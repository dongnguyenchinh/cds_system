class FormsController < ApplicationController
  before_action :form_service
  layout "system_layout"

  def index
  end

  def get_list_cds_assessment
    render json: @form_service.get_list_cds_assessment(current_user.id)
  end

  def get_competencies
    render json: @form_service.get_competencies(form_params[:form_id])
  end

  def cds_assessment
    form = Form.includes(:template).where(user_id: current_user.id, _type: "CDS").order(created_at: :desc).first
    @slots = if form.nil? || form.template.role_id != current_user.role_id
        @form_service.load_new_form
      else
        @form_service.load_old_form(form)
      end
  end

  def preview_result
    @role_name = Role.find(current_user.role_id).name
    @first_name = current_user.first_name
    @last_name = current_user.last_name
    form_id = Form.where(user_id: current_user.id, _type: "CDS").pluck(:id).first
    @competency = Competency.select(:name).where(template_id: form_id)
  end

  private

  def form_service
    @form_service ||= Api::FormService.new(form_params, current_user)
  end

  def form_params
    params.permit(:form_id, :template_id, :competency_id, :level, :user_ids)
  end
end
