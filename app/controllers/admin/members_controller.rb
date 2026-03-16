class Admin::MembersController < Admin::BaseController
  def index
    @members = User.where(role: :customer).order(created_at: :desc)
  end

  def show
    @member = User.find(params[:id])
  end

  def export
    @members = User.where(role: :customer).order(:last_name, :first_name)
    respond_to do |format|
      format.csv do
        headers["Content-Disposition"] = "attachment; filename=members-#{Date.today}.csv"
        headers["Content-Type"] = "text/csv"
      end
      format.html { redirect_to admin_members_path }
    end
  end
end
