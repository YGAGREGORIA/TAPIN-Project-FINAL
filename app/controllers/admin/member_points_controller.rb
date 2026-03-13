class Admin::MemberPointsController < Admin::BaseController
  def create
    @member = User.find(params[:member_id])
    points = params[:points].to_i

    @member.update(available_points: (@member.available_points || 0) + points)
    redirect_to admin_member_path(@member), notice: "#{points} points added to #{@member.first_name}."
  end
end
