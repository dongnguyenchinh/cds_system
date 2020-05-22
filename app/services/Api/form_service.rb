module Api
  class FormService
    LETTER_CAP = *("A".."Z")

    def initialize(params, current_user)
      @current_user = current_user
      @params = ActiveSupport::HashWithIndifferentAccess.new params.symbolize_keys
    end

    def get_competencies(template_id = nil)
      template_id ||= Template.find_by(role_id: current_user.role_id, status: true)&.id
      return [] if template_id.nil?

      Competency.select(:id, :name, :desc, :_type, :location).where(template_id: 1).order(:location)
    end

    def load_new_form(role_id = nil)
      role_id ||= current_user.role_id
      template_id = Template.find_by(role_id: role_id, status: true)&.id
      return [] if template_id.nil?
      competency_ids = get_competencies(1).map(&:id)
      slots = Slot.select(:id, :desc, :evidence, :level, :competency_id, :slot_id).includes(:competency, :form_slots).where(competency_id: competency_ids).order(:competency_id, :level, :slot_id)

      format_data_for_slot(slots)
    end

    def load_old_form(form)
      user_id = current_user.id
      form = Form.includes(:template).where(user_id: user_id, _type: "CDS").order(created_at: :desc).first

      slots = Slot.select(:id, :desc, :evidence, :level, :competency_id, :slot_id).includes(:competency, :form_slots).joins(:form_slots).where(form_slots: { form_id: form.id }).order(:competency_id, :level, :slot_id)

      form_slots = FormSlot.includes(:comments, :line_managers).where(form_id: form.id)

      format_data_for_slot(slots, form_slots)
    end

    def create_form_slot(slot_ids, template_id)
      form = Form.new(user_id: current_user.id, _type: "CDS", template_id: template_id)
      if form.save
        slot_ids.map do |id|
          FormSlot.create!(form_id: form.id, slot_id: id, is_passed: 0)
        end
      else
        false
      end
    end

    private

    attr_reader :params, :current_user

    def format_data_for_slot(slots, form_slots = nil)
      hash = {}
      dumy_hash = {} # count slot of level
      form_slots = format_form_slot(form_slots) if form_slots.present?
      slots.map do |slot|
        key_slot_id = "#{slot.competency_id}_#{slot.level}"
        dumy_hash[key_slot_id].nil? ? dumy_hash[key_slot_id] = [] : dumy_hash[key_slot_id] << 1

        key = slot.competency.name
        if hash[key].nil?
          hash[key] = {
            type: slot.competency.type,
            slots: [],
          }
        end
        
        hash[key][:slots] << slot_to_hash(slot, dumy_hash[key_slot_id].count, form_slots)
      end

      hash
    end

    def slot_to_hash(slot, location, form_slots)
      h_slot = {
        slot_id: slot.level + LETTER_CAP[location],
        desc: slot.desc,
        evidence: slot.evidence,
      }
      h_slot[:tracking] = form_slots[slot.id] if form_slots.present?

      h_slot
    end

    def format_form_slot(form_slots)
      hash = {}
      form_slots.map do |form_slot|
        recommends = get_recommend(form_slot.line_managers.order(created_at: :desc))
        comments = form_slot.comments.order(created_at: :desc).first

        if hash[form_slot.slot_id].nil?
          hash[form_slot.slot_id] = {
            comment: comments&.evidence || "",
            point: comments&.point || "",
            given_point: recommends[:given_point],
            recommends: recommends[:recommends],
            name: recommends[:name],
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
      }
      user = []
      line_managers.map do |line|
        unless user.include?(line.user_id)
          user << line.user_id
          hash[:given_point] << line.given_point
          hash[:recommends] << line.recommend
          hash[:name] << line.user_id
        end
      end
      hash[:name] = User.where(id: hash[:name]).pluck(:account)

      hash
    end
  end
end