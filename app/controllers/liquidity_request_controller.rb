class LiquidityRequestController < ApplicationController
  skip_before_action :verify_authenticity_token

  def new_liquidity_request
    if params[:command] == '/new_liquidity_request'
      response_url = params[:response_url]
      slack_service = SlackService.new
      slack_service.open_slack_modal(params[:trigger_id], response_url, senders)
      head :ok
    end
  end

  def create_liquidity_request
    payload = JSON.parse(params[:payload])

    if valid_callback_id?(payload)
      response_url = payload['view']['private_metadata']
      user_id = payload['user']['id']
      liquidity_request_params = build_liquidity_request_params(payload)
      admin_user_id = find_admin_user_id(user_id)
      liquidity_request = create_liquidity_request_record(liquidity_request_params.merge(created_by: admin_user_id))

      if liquidity_request.persisted?
        handle_successful_request(liquidity_request, response_url, payload)
      else
        render json: { text: "Failed to save liquidity request." }, status: :unprocessable_entity
      end
    else
      render json: { text: "Form submission failed." }, status: :bad_request
    end
  end

  private

  def valid_callback_id?(payload)
    payload['view']['callback_id'] == 'liquidity_request_form'
  end

  def build_liquidity_request_params(payload)
    {
      sender_id: extract_selected_value(payload, 'sender_name_block', 'sender_name_action'),
      payin_ccy: extract_selected_value(payload, 'payin_currency_block', 'payin_currency_action'),
      payout_ccy: extract_selected_value(payload, 'payout_currency_block', 'payout_currency_action'),
      amount: extract_value(payload, 'payout_amount_block', 'payout_amount_action'),
      negotiated_rate: extract_value(payload, 'rate_requested_block', 'rate_requested_action'),
      sender_class: 'standard',
      sender_type: 'recent'
    }
  end

  def extract_selected_value(payload, block_id, action_id)
    payload['view']['state']['values'][block_id][action_id]['selected_option']['value']
  end

  def extract_value(payload, block_id, action_id)
    payload['view']['state']['values'][block_id][action_id]['value']
  end

  def extract_sender_name(payload)
    payload['view']['state']['values']['sender_name_block']['sender_name_action']['selected_option']['text']['text']
  end

  def find_admin_user_id(user_id)
    user_email = SlackService.new.get_user_email(user_id)
    Admin::AdminUser.find_by_email(user_email)&.id || Admin::AdminUser.find_by_email('me@azafinance.com')&.id
  end

  def create_liquidity_request_record(params)
    Api::LiquidityRequest.create(params)
  end

  def handle_successful_request(liquidity_request, response_url, payload)
    response_message = build_response_message(liquidity_request, payload)

    render json: { response_action: 'clear' }, status: :ok

    Thread.new do
      response = SlackService.new.respond_to_slack(response_url, response_message)
      binding.pry
      liquidity_request.update!(metadata: liquidity_request.metadata.merge(slack_message_time: JSON.parse(response.body)['ts']))
    end
  end

  def build_response_message(liquidity_request, payload)
    "Trade requested:\n" \
      "#{extract_sender_name(payload)} has requested\n" \
      "#{liquidity_request.payin_ccy} > #{liquidity_request.payout_ccy}\n" \
      "They would like #{liquidity_request.amount} in volume.\n" \
      "They have requested a rate of #{liquidity_request.negotiated_rate}"
  end

  def senders
    senders = Api::Sender::Business.where(state: 2, type: 'Sender::Business')

    if senders.any?
      senders.map do |sender|
        {
          text: {
            type: 'plain_text',
            text: sender.details['name']
          },
          value: sender.id.to_s
        }
      end
    else
      [ { text: { type: 'plain_text', text: 'No Approved Senders' }, value: ' ' } ]
    end
  end
end
