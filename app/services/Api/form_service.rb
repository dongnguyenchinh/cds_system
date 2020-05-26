module Api
  class FormService < BaseService
    def initialize(params, current_user)
      @current_user = current_user
      @params = ActiveSupport::HashWithIndifferentAccess.new params
    end

    def get_competencies(form_id = nil)
      form_id = Form.select(:id).find_by(user_id: current_user.id).id if form_id.nil?
      slots = Slot.select(:id, :desc, :evidence, :level, :competency_id, :slot_id).includes(:competency).joins(:form_slots).where(form_slots: { form_id: form_id }).order(:competency_id, :level, :slot_id)
      hash = {}
      form_slots = FormSlot.includes(:comments).where(form_id: form_id)
      form_slots = format_form_slot(form_slots, true)
      slots.map do |slot|
        key = slot.competency.name
        if hash[key].nil?
          hash[key] = {
            type: slot.competency.sort_type,
            id: slot.competency_id,
            levels: {},
          }
        end
        if hash[key][:levels][slot.level].nil?
          hash[key][:levels][slot.level] = {
            total: 0,
            current: 0,
          }
        end
        hash[key][:levels][slot.level][:total] += 1
        hash[key][:levels][slot.level][:current] += 1 if form_slots[slot.id]
      end

      hash
    end

    def create_form_slot(role_id = nil)
      role_id ||= current_user.role_id
      template_id = Template.find_by(role_id: role_id, status: true)&.id
      return [] if template_id.nil?
      competency_ids = Competency.where(template_id: template_id).order(:location).pluck(:id)
      slot_ids = Slot.where(competency_id: competency_ids).order(:level, :slot_id).pluck(:id)

      form = Form.new(user_id: current_user.id, _type: "CDS", template_id: template_id, level: 2, rank: 2, title_id: 1002, role_id: 1, status: "New")
      form.clone
      if form.save
        slot_ids.map do |id|
          FormSlot.create!(form_id: form.id, slot_id: id, is_passed: 0)
        end
      end

      form.id
    end

    def get_list_cds_assessment(user_id = nil)
      user_id ||= current_user.id
      forms = Form.where(user_id: user_id, _type: "CDS").includes(:period, :role, :title).order(id: :desc)
      # binding.pry
      forms.map do |form|
        {
          id: form.id,
          period_name: form.period&.format_name || "New",
          role_name: form.role&.name,
          level: form.level,
          rank: form.rank,
          title: form.title&.name,
          status: form.status,
        }
      end
    end

    def format_data_slots(param = nil)
      param ||= params
      filter_slots = filter_cds
      filter = {
        form_slots: { form_id: param[:form_id] },
        competency_id: param[:competency_id],
      }
      filter[:level] = param[:level] if param[:level].present?
      slots = Slot.search_slots(params[:search]).joins(:form_slots).where(filter).order(:level, :slot_id)
      hash = {}
      form_slots = FormSlot.includes(:comments, :line_managers).where(form_id: param[:form_id], slot_id: slots.pluck(:id))
      form_slots = format_form_slot(form_slots)
      arr = []
      slots.map do |slot|
        if hash[slot.level].nil?
          hash[slot.level] = -1
        end
        hash[slot.level] += 1
        s = slot_to_hash(slot, hash[slot.level], form_slots)
        if filter_slots["passed"] && s[:tracking][:given_point].present? && s[:tracking][:given_point].max > 2
          arr << slot_to_hash(slot, hash[slot.level], form_slots)
        end
        if filter_slots["failed"] && s[:tracking][:given_point].present? && s[:tracking][:given_point].max < 3
          arr << slot_to_hash(slot, hash[slot.level], form_slots)
        end
        if filter_slots["no_assessment"] && s[:tracking][:evidence].empty?
          arr << slot_to_hash(slot, hash[slot.level], form_slots)
        end
        if filter_slots["need_to_update"] && s[:tracking][:need_to_update]
          arr << slot_to_hash(slot, hash[slot.level], form_slots)
        end
        if filter_slots["assessing"] && s[:tracking][:is_commit]
          arr << slot_to_hash(slot, hash[slot.level], form_slots)
        end
      end
      arr
    end

    def save_cds_staff
      if params[:is_commit] && params[:point] && params[:evidence] && params[:slot_id]
        form_slot = FormSlot.where(slot_id: params[:slot_id], form_id: params[:form_id]).first
        comment = Comment.where(form_slot_id: form_slot.id)
        if comment.present?
          comment.update(evidence: params[:evidence], point: params[:point], is_commit: params[:is_commit])
        else
          Comment.create!(evidence: params[:evidence], point: params[:point], is_commit: params[:is_commit], added_by: current_user.id, form_slot_id: form_slot.id)
        end
      end
    end

    def save_cds_manager
      if params[:recommend] && params[:given_point] && params[:slot_id]
        form_slot = FormSlot.where(slot_id: params[:slot_id], form_id: params[:form_id]).first
        line_manager = LineManager.where(user_id: current_user.id, form_slot_id: form_slot.id).first
        if line_manager.present?
          line_manager.update(recomend: params[:recommend], given_point: params[:given_point])
        else
          LineManager.create!(recomend: params[:recommend], given_point: params[:given_point], user_id: current_user.id, form_slot_id: form_slot.id)
        end
      end
    end

    private

    attr_reader :params, :current_user

    def slot_to_hash(slot, location, form_slots)
      h_slot = {
        slot_id: slot.level + LETTER_CAP[location],
        desc: slot.desc,
        evidence: slot.evidence,
      }
      h_slot[:tracking] = form_slots[slot.id] if form_slots.present?

      h_slot
    end

    def format_form_slot(form_slots, count = nil)
      hash = {}
      if count
        form_slots.map do |form_slot|
          hash[form_slot.slot_id] = form_slot.comments.present? if hash[form_slot.slot_id].nil?
        end
        return hash
      end

      form_slots.map do |form_slot|
        recommends = get_recommend(form_slot.line_managers.order(created_at: :desc))
        comments = form_slot.comments.order(created_at: :desc).first

        if hash[form_slot.slot_id].nil?
          hash[form_slot.slot_id] = {
            evidence: comments&.evidence || "",
            point: comments&.point || "",
            given_point: recommends[:given_point],
            recommends: recommends[:recommends],
            name: recommends[:name],
            count: recommends[:count],
          }
        end
      end

      hash
    end

    def get_recommend(line_managers)
      hash = {
        given_point: [],
        recommends: [],
        name: [],
        count: 0,
      }
      line_managers.map do |line|
        unless hash[:name].include?(line.user_id)
          hash[:given_point] << line.given_point
          hash[:recommends] << line.recommend
          hash[:name] << line.user_id
          hash[:count] += 1
        end
      end
      hash[:name] = User.where(id: hash[:name]).pluck(:account)

      hash
    end

    def filter_cds
      hash = {}
      params[:filter] = "failed,no_assessment,need_to_update,assessing" unless params[:filter].present?
      params[:filter].split(",").map do |p|
        hash[p] = true
      end
      hash
    end
  end
end
