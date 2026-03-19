class Admin::MemberPointsController < Admin::BaseController
  def create
    @member = User.find(params[:id])
    points = params[:points].to_i

    if points <= 0
      redirect_to admin_member_path(@member), alert: "Please enter a points value greater than 0."
      return
    end

    @member.with_lock do
      new_available_points = @member.available_points.to_i + points
      new_total_points = @member.total_points.to_i + points

      @member.update_columns(
        available_points: new_available_points,
        total_points: new_total_points
      )
    end

    redirect_to admin_member_path(@member), notice: "#{points} points added to #{@member.first_name}."
  end
end
