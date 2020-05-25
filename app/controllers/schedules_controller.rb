class SchedulesController < ApplicationController
  include Authorize
  before_action :get_privilege_id
  before_action :set_schedule, only: [:show, :edit, :update, :destroy]
  layout "system_layout"
  ROLE_NAME = ["PM", "SM", "BOD"]
  FULL_ACCESS_SCHEDULE_COMPANY = 13
  FULL_ACCESS_SCHEDULE_PROJECT = 14

  def get_schedule_data
    if (@privilege_array & [FULL_ACCESS_SCHEDULE_COMPANY, FULL_ACCESS_SCHEDULE_PROJECT]).any?
      company = Company.all

      current_user_role_name = Role.find(current_user.role_id).name

      company_id = current_user.company_id

      if check_hr?
        schedules = Schedule.joins(:user, :company).where(_type: "HR").search_schedule(set_params[:search]).offset(set_params[:offset]).limit(LIMIT).order(id: :DESC)
      elsif check_pm?
        schedules = Schedule.joins(:user, :company).where(_type: "PM").search_schedule(set_params[:search]).where(:"companies.id" => company_id).offset(set_params[:offset]).limit(LIMIT).order(id: :DESC)
      end

      render json: { iTotalRecords: schedules.count, iTotalDisplayRecords: schedules.unscope([:limit, :offset]).count, aaData: format_data(schedules) }
    else
      redirect_to root_path
    end
  end

  def check_pm?
    return false if @privilege_array.include?(FULL_ACCESS_SCHEDULE_COMPANY) && @privilege_array.include?(FULL_ACCESS_SCHEDULE_PROJECT)
    return true if @privilege_array.include?(FULL_ACCESS_SCHEDULE_PROJECT)
  end

  def check_hr?
    return true if @privilege_array.include?(FULL_ACCESS_SCHEDULE_COMPANY) && @privilege_array.include?(FULL_ACCESS_SCHEDULE_PROJECT)
    return true if @privilege_array.include?(FULL_ACCESS_SCHEDULE_COMPANY)
  end

  def get_schedule_hr_info
    temp_params = hr_schedule_params
    schedule_id = temp_params[:id]

    begin
      schedule_hr = Schedule.find(schedule_id)
      render json: { status: "success", start_date_hr: schedule_hr.start_date.strftime("%b %d, %Y"), end_date_hr: schedule_hr.end_date_hr.strftime("%b %d, %Y") }
    rescue
      render json: { status: "fail" }
    end
  end

  def format_data(schedules)
    schedules.map.with_index do |schedule, index|
      current_schedule_data = []

      if schedule.status == "New"
        current_schedule_data.push("<input type='checkbox' name='checkbox' id='schedule_ids_' value='#{schedule.id}' class='selectable'>")
      else
        current_schedule_data.push("")
      end

      number = set_params[:offset] + index + 1
      current_schedule_data.push("<td style='text-align:right'>#{number}</td>")
      current_schedule_data.push("<td><a class='view_detail' data-schedule='#{schedule.id}' href='javascript:void(0)'>#{schedule.desc}</a></td>")

      next if schedule.company.id != current_user.company_id && check_pm?

      current_schedule_data.push(schedule.company.name)

      if check_pm?
        project_ids = ProjectMember.where(user_id: current_user.id, :is_managent => true).pluck(:project_id)
        project_name = Project.find(project_ids).pluck(:desc).join(", ")
        current_schedule_data.push(project_name)
      end

      current_schedule_data.push("#{schedule.period.from_date.strftime("%b %d, %Y")} - #{schedule.period.to_date.strftime("%b %d, %Y")}")
      current_schedule_data.push(schedule.start_date.strftime("%b %d, %Y"))
      current_schedule_data.push(schedule.end_date_hr.strftime("%b %d, %Y"))
      current_schedule_data.push(schedule.status)

      if schedule.status.nil?
        # avoid error if status is nil
      elsif schedule.status.downcase == "in-progress"
        if schedule._type == "HR"
          current_schedule_data.push("<td style='text-align: center;'>      
          <a class='edit_btn' enable='true' data-schedule='#{schedule.id}' data-tooltip='true' data-placement='top' title='' href='javascript:void(0)' data-original-title='Edit schedule'><i class='fa fa-pencil icon' style='color:#fc9803'></i></a>
          <a class='del_btn'  href='javascript:void(0)' data-original-title='Delete schedule'><i class='fa fa-trash icon' style='color:#000'></i></a>
        </td>")
        elsif schedule._type == "PM"
          current_schedule_data.push("<td style='text-align: center;'>      
            <a class='edit_btn' enable='true' data-schedule='#{schedule.id}' data-tooltip='true' data-placement='top' title='' href='javascript:void(0)' data-original-title='Edit schedule'><i class='fa fa-pencil icon' style='color:#fc9803'></i></a>
            <a class='del_btn'  href='javascript:void(0)' data-original-title='Delete schedule'><i class='fa fa-trash icon' style='color:#000'></i></a>
          </td>")
        end
      elsif schedule.status.downcase == "new"
        if schedule._type == "HR"
          current_schedule_data.push("<td style='text-align: center;'>      
          <a class='edit_btn' enable='true' data-schedule='#{schedule.id}' data-tooltip='true' data-placement='top' title='' href='javascript:void(0)' data-original-title='Edit schedule'><i class='fa fa-pencil icon' style='color:#fc9803'></i></a>
          <a class='del_btn'  enable='true' data-schedule='#{schedule.id}' data-tooltip='true' data-placement='top' title='' href='javascript:void(0)' data-original-title='Delete schedule'><i class='fa fa-trash icon' style='color:red'></i></a>
        </td>")
        elsif schedule._type == "PM"
          current_schedule_data.push("<td style='text-align: center;'>      
          <a class='edit_btn' enable='true' data-schedule='#{schedule.id}' data-tooltip='true' data-placement='top' title='' href='javascript:void(0)' data-original-title='Edit schedule'><i class='fa fa-pencil icon' style='color:#fc9803'></i></a>
          <a class='del_btn'  href='javascript:void(0)' data-original-title='Delete schedule'><i class='fa fa-trash icon' style='color:#000'></i></a>
        </td>")
        end
      else
        current_schedule_data.push("")
      end
    end
  end

  def set_params
    {
      offset: params[:iDisplayStart].to_i,
      search: params[:sSearch],
    }
  end

  def index
    if check_hr?
      @fields = ["No.", "Schedule name", "Company name", "Assessment period", "Start date", "Status", "Action"]
    elsif check_pm?
      @fields = ["No.", "Schedule name", "Company name", "Project Name", "Assessment period", "Start date", "Status", "Action"]
    end

    if check_hr? && (@privilege_array & [FULL_ACCESS_SCHEDULE_COMPANY]).any?
      @fields.insert(5, "End date")
    elsif check_pm? && (@privilege_array & [FULL_ACCESS_SCHEDULE_PROJECT]).any?
      @fields.insert(6, "End date")
    else
      redirect_to root_path
    end

    @schedules = Schedule.includes(:user, :company).order(id: :DESC).page(params[:page]).per(20)
    @is_pm = check_pm?
    @is_hr = check_hr?

    @company = Company.where(id: current_user.company_id)

    project_ids = ProjectMember.where(user_id: current_user.id, is_managent: 1).pluck(:project_id)
    @project = Project.where(id: project_ids)
    @parent_schedules = Schedule.joins(:period).select(:id, "(CONCAT(DATE_FORMAT(from_date, '%b %d, %Y') , ' - ' , DATE_FORMAT(to_date, '%b %d, %Y'))) AS parent_period").where(_type: "HR", status: ["New", "In-Progress"])
  end

  def new
    @schedule = Schedule.new
  end

  def show
    @schedule = Schedule.includes(:company, :period).find(params[:id])

    respond_to do |format|
      format.js
    end
  end

  def mailer
  end

  def create
    # format date from schedule
    temp_params = schedule_params

    if check_hr?
      temp_params[:end_date_hr] = helpers.date_format(params[:end_date_hr])
      temp_params[:start_date] = helpers.date_format(params[:start_date])
      temp_params[:_type] = "HR"
      # format date from period
      period_params_temp = period_params
      period_params_temp[:from_date] = helpers.date_format(params[:from_date])
      period_params_temp[:to_date] = helpers.date_format(params[:to_date])

      @period = Period.new(period_params_temp)
      respond_to do |format|
        if @period.save
          temp_params[:period_id] = @period.id
          @schedule = Schedule.new(temp_params)
          if @schedule.save
            @schedules = Schedule.order(id: :DESC).page(params[:page]).per(20)
            user = User.joins(:role, :company).where("roles.name": ROLE_NAME, is_delete: false, "companies.id": params[:company_id])
            # send mail
            ScheduleMailer.with(user: user.to_a, schedule: @schedule, period: @period).notice_mailer.deliver_later(wait: 1.minute)
            format.js { @status = true }
          else
            format.js { @status = false }
          end
        else
          format.js { @status = false }
        end
      end
    elsif check_pm?
      temp_params[:end_date_employee] = temp_params[:end_date_member]

      temp_params.delete(:end_date_member)
      temp_params[:notify_employee] = temp_params[:notify_member]
      temp_params[:notify_reviewer] = temp_params[:notify_member]
      temp_params.delete(:notify_member)
      schedule_parent_id = temp_params[:schedule_hr_parent]
      temp_params.delete(:schedule_hr_parent)

      temp_params[:end_date_hr] = helpers.date_format(params[:end_date_hr])
      temp_params[:start_date] = helpers.date_format(params[:start_date])
      temp_params[:_type] = "PM"

      # reuse existing period of parents
      parent_schedule = Schedule.find(schedule_parent_id)
      period = Period.find(parent_schedule.period_id)
      temp_params[:period_id] = period.id
      temp_params[:notify_hr] = parent_schedule.notify_hr
      @schedule = Schedule.new(temp_params)

      respond_to do |format|
        if @schedule.save
          @schedules = Schedule.order(id: :DESC).page(params[:page]).per(20)
          #user = User.joins(:role, :company).where("roles.name": ROLE_NAME, is_delete: false, "companies.id": params[:company_id])
          # send mail
          #ScheduleMailer.with(user: user.to_a, schedule: @schedule, period: @period).notice_mailer.deliver_later(wait: 1.minute)
          format.js { @status = true }
        else
          format.js { @status = false }
        end
      end
    end
  end

  def edit_page
    respond_to do |format|
      @schedule = Schedule.find(params[:id])
      @company = Company.where(id: current_user.company_id)

      @schedule[:end_date_hr] = DateTime.strptime(@schedule[:end_date_hr].to_s, "%Y-%m-%d").strftime("%Y-%m-%d")
      @schedule[:start_date] = DateTime.strptime(@schedule[:start_date].to_s, "%Y-%m-%d").strftime("%Y-%m-%d")

      @is_pm = check_pm?
      @is_hr = check_hr?
      project_ids = ProjectMember.where(user_id: current_user.id, is_managent: 1).pluck(:project_id)
      @project = Project.where(id: project_ids)
      @parent_schedules = Schedule.joins(:period).select(:id, "(CONCAT(DATE_FORMAT(periods.from_date, '%b %d, %Y') , ' - ' , DATE_FORMAT(periods.to_date, '%b %d, %Y'))) AS parent_period").where(_type: "HR", status: "New", end_date_hr: @schedule[:end_date_hr], start_date: @schedule[:start_date]).limit(1)
      format.js
    end
  end

  def destroy_page
    @schedule = Schedule.find(params[:id])

    respond_to do |format|
      format.js
    end
  end

  def destroy
    @schedule = Schedule.find(params[:id])
    @period = Period.find(@schedule.period_id)
    respond_to do |format|
      @period = Period.find(@schedule.period_id)
      user = User.joins(:role, :company).where("roles.name": ROLE_NAME, is_delete: false, "companies.id": @schedule.company_id)
      ScheduleMailer.with(user: user.to_a, period: @period).del_mailer.deliver_later(wait: 1.minute)

      if check_hr?
        if @period.destroy && @schedule.destroy
          #@schedules = Schedule.order(id: :DESC).page(params[:page]).per(20)
          format.js { @status = true }
        else
          format.js { @status = false }
        end
      elsif check_pm?
        format.js { @status = false }
      end
    end
  end

  def destroy_multiple
    respond_to do |format|
      if params[:schedule_ids] != nil
        schedule = Schedule.find(params[:schedule_ids])

        schedule.each do |schedule|
          period = Period.find(schedule.period_id)
          user = User.joins(:role, :company).where("roles.name": ROLE_NAME, is_delete: false, "companies.id": schedule.company_id)
          ScheduleMailer.with(user: user.to_a, period: period).del_mailer.deliver_later(wait: 1.minute)
          schedule.destroy
        end
        @schedules = Schedule.order(id: :DESC).page(params[:page]).per(20)
        format.js { @status = true }
      else
        format.js { @status = false }
      end
    end
  end

  def update
    if check_hr?
      temp_params = schedule_params
      temp_params[:end_date_hr] = helpers.date_format(params[:end_date_hr])
    elsif check_pm?
      temp_params = pm_update_schedules_param
      temp_params[:end_date_employee] = helpers.date_format(params[:end_date_member])
      temp_params[:end_date_reviewer] = helpers.date_format(params[:end_date_reviewer])
      temp_params.delete(:end_date_member)
      temp_params[:notify_employee] = temp_params[:notify_member]
      temp_params[:notify_reviewer] = temp_params[:notify_member]
      temp_params.delete(:notify_member)
    end

    @schedule = Schedule.find(params[:id])
    respond_to do |format|
      if @schedule.update(temp_params)
        user = User.joins(:role, :company).where("roles.name": ROLE_NAME, is_delete: false, "companies.id": @schedule.company_id)
        @period = Period.find(@schedule.period_id)
        if check_hr?
          ScheduleMailer.with(user: user.to_a, schedule: @schedule, period: @period).edit_mailer_hr.deliver_later(wait: 1.minute)
        elsif check_pm?
          ScheduleMailer.with(user: user.to_a, schedule: @schedule, period: @period).edit_mailer_pm.deliver_later(wait: 1.minute)
        end
        @schedules = Schedule.order(id: :DESC).page(params[:page]).per(20)
        format.js { @status = true }
      else
        format.js { @status = false }
      end
    end
  end

  private

  def check_privilege
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_schedule
    @schedule = Schedule.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def schedule_params
    params.permit(:id, :project_id, :period_id, :schedule_hr_parent, :start_date, :end_date_hr, :end_date_member, :end_date_reviewer, :notify_reviewer, :company_id, :user_id, :desc, :status, :notify_employee, :notify_member, :is_delete, :notify_hr)
  end

  def hr_schedule_params
    params.permit(:id)
  end

  def pm_update_schedules_param
    params.permit(:id, :end_date_member, :end_date_reviewer, :notify_member)
  end

  def period_params
    params.permit(:id, :from_date, :to_date)
  end
end
