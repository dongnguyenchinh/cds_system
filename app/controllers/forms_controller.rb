class FormsController < ApplicationController
  include TitleMappingsHelper
  layout "system_layout"
  before_action :form_service
  before_action :export_service
  before_action :get_privilege_id
  before_action :check_privilege
  VIEW_CDS_CDP_ASSESSMENT = 15
  REVIEW_CDS = 16
  APPROVE_CDS = 17
  FULL_ACCESS = 24

  def index_cds_cdp
  end

  def get_list_cds_assessment_manager
    data = if @privilege_array.include?(APPROVE_CDS) || @privilege_array.include?(REVIEW_CDS)
        @form_service.get_list_cds_review
      else
        redirect_to root_path
      end
    render json: data
  end

  def get_summary_comment
    render json: @form_service.get_summary_comment
  end

  def save_summary_comment
    render json: @form_service.save_summary_comment
  end

  def cancel_request
    form_slot_ids = params[:form_slot_id].map(&:to_i)
    render json: @form_service.cancel_request(form_slot_ids, params[:slot_id])
  end

  def export_excel_cds_review
    file_path = ""
    if @privilege_array.include?(APPROVE_CDS) || @privilege_array.include?(REVIEW_CDS)
      data = @form_service.get_list_cds_review_to_export
    end
    file_path = @export_service.export_excel_cds_review(data)
    render json: { file_path: file_path }
  end

  def get_list_cds_assessment
    render json: @form_service.get_list_cds_assessment(current_user.id)
  end

  def get_competencies
    render json: @form_service.get_competencies(form_params[:form_id])
  end

  def get_competencies_reviewer
    render json: @form_service.get_competencies_reviewer(form_params[:form_id])
  end

  def cds_review
    @companies = Company.all
    @data_filter = if @privilege_array.include?(FULL_ACCESS)
        @form_service.data_filter_cds_view_others
      elsif @privilege_array.include?(APPROVE_CDS)
        @form_service.data_filter_cds_approve
      elsif @privilege_array.include?(REVIEW_CDS)
        @form_service.data_filter_cds_review
      else
        redirect_to root_path
      end
  end

  def cdp_assessment
    @check_5_month = true
    @check_5_month = current_user.joined_date.to_i < 5.months.ago.to_i if current_user.joined_date
    params = form_params
    user = if params[:form_id].present?
        Form.includes(:user).find_by_id(params[:form_id])&.user
      else
        current_user
      end

    @user = {
      format_name: user.format_name,
      role_name: user.role&.name || "",
    }
    @hash = {}
    schedules = Schedule.includes(:period).where(company_id: current_user.company_id).where.not(status: "Done").order(:period_id)
    @period = schedules.map do |schedule|
      {
        id: schedule.period_id,
        name: schedule.period.format_name,
      }
    end
    if params[:title_history_id].present?
      @hash[:status] = "Done"
      @hash[:title_history_id] = params[:title_history_id]
      @hash[:title] = "CDS/CDP Assessment for " + TitleHistory.find_by_id(params[:title_history_id]).period.format_name
      return @hash
    end
    if params.include?(:form_id)
      form = Form.where(user_id: current_user.id, id: params[:form_id]).first
      return if form.nil?
    else
      template_id = Template.find_by(role_id: current_user.role_id, status: true)&.id
      return if template_id.nil?
      form = Form.includes(:template).where(user_id: current_user.id).order(created_at: :desc).first
    end
    if form.nil? || form.template.role_id != current_user.role_id
      form = @form_service.create_form_slot
    else
      form.update(status: "New", period_id: nil, is_delete: false) if form.status == "Done"
    end
    @hash[:form_id] = form.id
    @hash[:status] = form.status
    @hash[:title] = form.period&.format_name.present? ? "CDS/CDP Assessment for " + form.period&.format_name : "New CDS/CDP Assessment"
  end

  def request_update_cds
    form_slot_ids = params[:form_slot_id].map(&:to_i)
    render json: @form_service.request_update_cds(form_slot_ids, params[:slot_id])
  end

  def cds_cdp_review
    return if params[:user_id].nil?
    reviewer = Approver.find_by(user_id: params[:user_id], approver_id: current_user.id)
    schedules = Schedule.includes(:period).where(company_id: current_user.company_id).where.not(status: "Done").order(:period_id)
    @period = schedules.map do |schedule|
      {
        id: schedule.period_id,
        name: schedule.period.format_name,
      }
    end

    form = Form.where(id: params[:form_id]).first
    user = User.includes(:role).find_by_id(params[:user_id])
    approver = Approver.find_by(approver_id: current_user.id, user_id: params[:user_id])

    @hash = {
      user_id: params[:user_id],
      user_name: user.format_name,
      form_id: form.id,
      status: form.status,
      title: "CDS/CDP of #{user.role.name} - #{user.account}",
      is_submit: approver.is_submit_cds,
      is_approver: approver.is_approver,
      is_reviewer: !approver.is_approver,
    }
  end

  def get_assessment_staff
    render json: @form_service.get_assessment_staff
  end

  def get_cds_assessment
    render json: @form_service.format_data_slots
  end

  def get_slot_is_change
    render json: @form_service.get_slot_change
  end

  def confirm_request
    render json: @form_service.confirm_request
  end

  def save_cds_assessment_staff
    return render json: { status: "success" } if @form_service.save_cds_staff
    render json: { status: "fail" }
  end

  def save_add_more_evidence
    return render json: { status: "success" } if @form_service.save_add_more_evidence
    render json: { status: "fail" }
  end

  def request_add_more_evidence
    data = @form_service.request_add_more_evidence
    return render json: { status: "success", color: data } if data.present?
    render json: { status: "fail" }
  end

  def save_cds_assessment_manager
    return render json: { status: "success" } if @form_service.save_cds_manager
    render json: { status: "fail" }
  end

  def get_data_slot
    return render json: @form_service.get_data_form_slot
  end

  def get_conflict_assessment
    return render json: @form_service.get_conflict_assessment
  end

  def preview_result
    return redirect_to forms_path if params[:form_id].nil?
    form = Form.includes(:title).find_by_id(params[:form_id])
    # return redirect_to forms_path if form.nil? || form.user_id != current_user.id && (@privilege_array & [APPROVE_CDS, REVIEW_CDS]).any?
    @form_id = form.id
    @competencies = Competency.where(template_id: form.template_id).select(:name, :id)
    @result = @form_service.preview_result(form)
    user = User.includes(:role).find_by_id(form.user_id)
    @title = "View CDS/CDP Result For #{user.role.desc} - #{user.format_name}"
    @slots = @result.values.map(&:keys).flatten.uniq.sort
  end

  def data_view_result
    render json: { data: @form_service.data_view_result }
  end

  def destroy
    form = Form.find_by_id(params[:id])
    return render json: { status: "can't delete form" } if current_user.role_id == form.role_id || form.status != "New"
    if form.update(is_delete: true)
      render json: { status: "success" }
    else
      render json: { status: "fail" }
    end
  end

  def submit
    form = Form.find_by_id(params[:form_id])
    users = User.joins(:approvers).where("approvers.user_id": form.user_id)
    action = "review"
    if users.empty?
      action = "approve"
      project_ids = ProjectMember.where(user_id: current_user.id).pluck(:project_id)
      user_ids = ProjectMember.where(project_id: project_ids).pluck(:user_id)
      users = User.joins(user_group: [:group]).where(id: user_ids).where("groups.privileges like '%17%'")
      return render json: { status: "fail" } if users.empty?
    else
      render json: { status: "success" } if form.update(period_id: params[:period_id].to_i,
                                                        status: "Awaiting Review", submit_date: DateTime.now)
    end
    user = form.user
    period = form.period

    CdsAssessmentMailer.with(user: user, from_date: period.from_date, to_date: period.to_date, approvers: users.to_a, action: action).
      user_submit.deliver_later(wait: 1.minute)
  end

  def reviewer_submit
    reviewer = Approver.where(user_id: params[:user_id], approver_id: current_user.id)
    project_ids = ProjectMember.where(user_id: params[:user_id]).pluck(:project_id)
    #user_ids = ProjectMember.where(project_id: project_ids).pluck(:user_id)
    # get PM from same project user list
    user_pms = Approver.where(is_submit_cds: false, is_approver: true).pluck(:approver_id)

    ActiveRecord::Base.transaction do
      if reviewer.update(is_submit_cds: true)
        approvers = Approver.where(user_id: params[:user_id]).includes(:approver)
        user = User.find_by_id(params[:user_id])
        if approvers.where(is_submit_cds: false, is_approver: false).where.not(approver_id: user_pms).count.zero?
          form = Form.where(id: params[:form_id])
          return render json: { status: "fail" } unless form.update(status: "Awaiting Approval", review_date: DateTime.now())
          user_pms.each do |user_pm|
            CdsAssessmentMailer.with(staff: user, pm: User.find(user_pm)).email_to_pm.deliver_later(wait: 1.minute)
          end
        end
        render json: { status: "success", user_name: user.format_name }
      else
        render json: { status: "fail" }
      end
    end
  end

  def approve_cds
    user_name = User.find_by_id(params[:user_id]).format_name
    status = @form_service.approve_cds
    render json: { status: status, user_name: user_name }
  end

  def reject_cds
    user_name = User.find_by_id(params[:user_id]).format_name
    status = @form_service.reject_cds
    render json: { status: status, user_name: user_name }
  end

  def withdraw_cds
    user_name = current_user.format_name
    status = @form_service.withdraw_cds
    render json: { status: status, user_name: user_name }
  end

  def get_cds_histories
    render json: @form_service.get_data_view_history
  end

  def review_cds_assessment
    params = form_params
    @hash = {}
    schedules = Schedule.includes(:period).where(company_id: 1).where.not(status: "Done").order(:period_id)
    @period = schedules.map do |schedule|
      {
        id: schedule.period_id,
        name: schedule.period.format_name,
      }
    end
    return title_history_id = params[:title_history_id] if params[:title_history_id].present?
    if params.include?(:form_id)
      form = Form.where(user_id: current_user.id, id: params[:form_id]).first
      return if form.nil?
    else
      form = Form.includes(:template).where(user_id: current_user.id).order(created_at: :desc).first
    end
    @hash[:title_history_id] = title_history_id
    form_id = if form.nil? || form.template.role_id != current_user.role_id
        @form_service.create_form_slot
      else
        form.update(status: "New", period_id: nil) if form.status == "Done"
        form.id
      end
    @hash[:form_id] = form_id
    @hash[:status] = form.status
  end

  def get_filter
    data = if @privilege_array.include?(FULL_ACCESS)
        @form_service.data_filter_cds_view_others
      elsif @privilege_array.include?(APPROVE_CDS)
        @form_service.data_filter_cds_approve
      elsif @privilege_array.include?(REVIEW_CDS)
        @form_service.data_filter_cds_review
      else
        redirect_to root_path
      end
    render json: data
  end

  private

  def get_privilege_assessment
    user_id = Form.where(id: params[:form_id]).pluck(:user_id)
    project_ids = ProjectMember.where(user_id: user_id).pluck(:project_id)
    user_ids = ProjectMember.where(project_id: project_ids).pluck(:user_id)
    @is_reviewer = false
    @is_approver = false
    if @privilege_array.include?(REVIEW_CDS) && user_ids.include?(current_user.id)
      @is_reviewer = true
    end
    if @privilege_array.include?(APPROVE_CDS) && user_ids.include?(current_user.id)
      @is_reviewer = false
      @is_approver = true
    end
  end

  def check_privilege
    get_privilege_assessment
    if (@is_reviewer || @is_approver)
      check_line_manager_privilege
    else
      check_staff_privilege
    end
  end

  def check_staff_privilege
    redirect_to root_path unless @privilege_array.include?(VIEW_CDS_CDP_ASSESSMENT)
  end

  def check_line_manager_privilege
    redirect_to root_path unless (@privilege_array.include?(REVIEW_CDS) || @privilege_array.include?(APPROVE_CDS))
  end

  def form_service
    @form_service ||= Api::FormService.new(form_params, current_user)
  end

  def export_service
    @export_service ||= Api::ExportService.new(form_params, current_user)
  end

  def form_params
    params[:offset] = params[:iDisplayStart] || "0"
    params[:user_ids] = params[:user_ids] || "0"
    params[:company_ids] = params[:company_ids] || "0"
    params[:project_ids] = params[:project_ids] || "0"
    params[:period_ids] = params[:period_ids] || "50"
    params[:role_ids] = params[:role_ids] || "0"

    params.permit(:form_id, :template_id, :competency_id, :level, :user_id, :is_commit,
                  :point, :evidence, :given_point, :recommend, :search, :filter, :slot_id,
                  :period_id, :title_history_id, :form_slot_id, :competency_name, :offset,
                  :user_ids, :company_ids, :project_ids, :period_ids, :role_ids, :type,
                  :cancel_slots, :summary_id, :comment, :ext)
  end
end
