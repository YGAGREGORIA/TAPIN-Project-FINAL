class Admin::MemberRewardsController < Admin::BaseController
  def create
    @member = User.find(params[:member_id])
    @reward = Reward.find(params[:reward_id])

    redemption = RewardRedemption.new(
      user: @member,
      reward: @reward,
      studio: @reward.studio,
      code: "ADMIN-#{SecureRandom.hex(4).upcase}",
      redeemed_at: Time.current,
      expiry_days: 30,
      point_spent: 0,
      status: true
    )

    if redemption.save
      redirect_to admin_member_path(@member), notice: "Reward granted to #{@member.first_name}."
    else
      redirect_to admin_member_path(@member), alert: redemption.errors.full_messages.to_sentence
    end
  end
end
