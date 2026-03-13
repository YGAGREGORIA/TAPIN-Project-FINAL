class MessagesController < ApplicationController
  before_action :authenticate_user!

  SYSTEM_PROMPT = <<~PROMPT
    You are the TapIn AI assistant helping users at a fitness studio.
    You help with check-ins, rewards, loyalty progress, classes, deals, and general studio info.
    Be concise, friendly, and helpful. Use the data provided — never make up numbers.
  PROMPT

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @studio = @chat.studio

    user_text = params[:message].to_s.strip
    return render json: { error: "empty_message" }, status: :unprocessable_entity if user_text.blank?

    # Save user message
    Message.create!(role: "user", content: user_text, chat: @chat)

    # Generate response
    assistant_text = generate_customer_response(user_text)

    # Save assistant message
    Message.create!(role: "assistant", content: assistant_text, chat: @chat)

    # Auto-rename chat from first message
    new_title = maybe_rename_chat(user_text)

    render json: { assistant: assistant_text, title: new_title }
  end

  private

  def maybe_rename_chat(user_text)
    return nil unless @chat.title&.match?(/\AChat \d+\z/)

    title = user_text.truncate(40, omission: "...")
    @chat.update!(title: title)
    title
  end

  def generate_customer_response(user_text)
    text = user_text.downcase

    case text
    when /check.?in|visit|attendance|how many/
      count = current_user.visits_count_for(@studio)
      progress = current_user.current_visit_progress_for(@studio)
      remaining = current_user.visits_remaining_for_next_reward(@studio)
      "You have #{count} visits at #{@studio.name}! " \
      "You're #{progress}/10 towards your next free class (#{remaining} more to go)."

    when /reward|unlock|earn|free class|milestone/
      if current_user.free_class_reward_available_for?(@studio)
        "You have a free class reward available! Head to the rewards page to redeem it."
      else
        remaining = current_user.visits_remaining_for_next_reward(@studio)
        progress = current_user.current_visit_progress_for(@studio)
        "You're #{progress}/10 visits towards your next free class. #{remaining} more to go — keep it up!"
      end

    when /class|recommend|workout|exercise|train|schedule/
      classes = @studio.class_configs.pluck(:class_name, :point_value, :is_premium)
      lines = classes.map do |name, pts, premium|
        "#{name} (#{pts} pts#{premium ? ', premium' : ''})"
      end
      "Classes at #{@studio.name}:\n#{lines.join("\n")}"

    when /deal|offer|discount|promo|special/
      deals = @studio.deals.active.pluck(:name, :discount_percent)
      if deals.any?
        lines = deals.map { |name, pct| "#{name} — #{pct}% off" }
        "Active deals:\n#{lines.join("\n")}"
      else
        "No active deals right now, but check back soon!"
      end

    when /book|upcoming|next class|my class/
      bookings = current_user.bookings.where(studio: @studio, status: true)
                             .where("class_time > ?", Time.current)
                             .order(:class_time).limit(3)
      if bookings.any?
        lines = bookings.map { |b| "#{b.class_name} — #{b.class_time.strftime('%a %b %d, %-I:%M %p')}" }
        "Your upcoming classes:\n#{lines.join("\n")}"
      else
        "You don't have any upcoming bookings. Check out the class schedule!"
      end

    when /referral|invite|friend|share/
      active = current_user.referrals.active.count
      "You have #{active}/5 active referral links. Share one with a friend — you'll both get 50% off when they complete their first visit!"

    when /point|progress|status|tier/
      count = current_user.visits_count_for(@studio)
      milestones = current_user.reward_milestones_reached_for(@studio)
      remaining = current_user.visits_remaining_for_next_reward(@studio)
      "You have #{count} total visits and #{milestones} milestone(s) reached. " \
      "#{remaining} more visit(s) until your next free class!"

    when /hi|hello|hey|help|what can you/
      name = current_user.first_name.present? ? ", #{current_user.first_name}" : ""
      "Hey#{name}! I can help you with:\n" \
      "- Your visit count and reward progress\n" \
      "- Available rewards and deals\n" \
      "- Class schedule and bookings\n" \
      "- Referral links\n" \
      "Just ask me anything!"

    else
      call_llm
    end
  end

  def call_llm
    chat = RubyLLM.chat(model: "gpt-4.1-mini")

    history = @chat.messages.order(:created_at).map do |m|
      { role: m.role, content: m.content }
    end

    response = chat.with_instructions(SYSTEM_PROMPT).ask(history)
    response.content
  rescue StandardError => e
    Rails.logger.error("LLM error: #{e.class} - #{e.message}")
    "I'm not sure how to help with that yet. Try asking about your visits, rewards, classes, or deals!"
  end
end
