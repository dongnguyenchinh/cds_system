class UserGroupsController < ApplicationController
  layout "system_layout"
  # GET /user_groups
  # GET /user_groups.json
  def index
    @user_groups = UserGroup.all
    @user = AdminUser.all
  end
  def load_user
    user_groups = UserGroup.where(group_id: params[:id]).pluck(:admin_user_id)
    list_user = AdminUser.where().not(is_delete: true,id: user_groups)
    render json: list_user
  end
  def load_group
    group = Group.find_by_id(params[:id])
    render json: group
  end
  def load_user_group
    @kq = UserGroup.includes(:group, :admin_user).where(group_id: params[:id])
    arr = Array.new
    @kq.each{|kq|
      arr << {
        id: kq.id,
        group_name: kq.group.name,
        admin_user_id: kq.admin_user_id,
        group_id: kq.group_id,
        first_name: kq.admin_user.first_name,
        last_name: kq.admin_user.last_name,
        email: kq.admin_user.email
      }
    }
    render json: arr
  end
  def save_user_group
    list_users = params[:list]
    id_group = params[:id]
    UserGroup.delete_by(group_id: id_group)
    if list_users.present? 
      list_users.each{ |user| 
        UserGroup.create(group_id: id_group, admin_user_id: user)
    }
    end 
    render json: "1"
  end
end
