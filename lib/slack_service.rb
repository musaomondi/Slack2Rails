class SlackService
  def initialize(token = ENV['SLACK_BOT_TOKEN'])
    @slack_client = Slack::Web::Client.new(token: token)
  end

  def open_slack_modal(trigger_id, response_url, senders)
    modal_view = {
      type: 'modal',
      callback_id: 'liquidity_request_form',
      private_metadata: response_url,
      title: {
        type: 'plain_text',
        text: 'New Liquidity Request'
      },
      close: {
        type: 'plain_text',
        text: 'Close'
      },
      submit: {
        type: 'plain_text',
        text: 'Submit'
      },
      blocks: [
        {
          type: 'input',
          block_id: 'sender_name_block',
          element: {
            type: 'static_select',
            action_id: 'sender_name_action',
            placeholder: {
              type: 'plain_text',
              text: 'Select Sender Name'
            },
            options: senders
          },
          label: {
            type: 'plain_text',
            text: 'Sender Name'
          }
        },
        {
          type: 'input',
          block_id: 'payin_currency_block',
          element: {
            type: 'static_select',
            action_id: 'payin_currency_action',
            placeholder: {
              type: 'plain_text',
              text: 'Select Payin Currency'
            },
            options: [
              { text: { type: 'plain_text', text: 'NGN' }, value: 'NGN' },
              { text: { type: 'plain_text', text: 'GHS' }, value: 'GHS' },
              { text: { type: 'plain_text', text: 'KES' }, value: 'KES' },
              { text: { type: 'plain_text', text: 'ZAR' }, value: 'ZAR' },
              { text: { type: 'plain_text', text: 'USD' }, value: 'USD' },
              { text: { type: 'plain_text', text: 'GBP' }, value: 'GBP' }
            ]
          },
          label: {
            type: 'plain_text',
            text: 'Payin Currency'
          }
        },
        {
          type: 'input',
          block_id: 'payout_currency_block',
          element: {
            type: 'static_select',
            action_id: 'payout_currency_action',
            placeholder: {
              type: 'plain_text',
              text: 'Select Payout Currency'
            },
            options: [
              { text: { type: 'plain_text', text: 'NGN' }, value: 'NGN' },
              { text: { type: 'plain_text', text: 'GHS' }, value: 'GHS' },
              { text: { type: 'plain_text', text: 'ZAR' }, value: 'ZAR' },
              { text: { type: 'plain_text', text: 'USD' }, value: 'USD' },
              { text: { type: 'plain_text', text: 'GBP' }, value: 'GBP' },
              { text: { type: 'plain_text', text: 'CAD' }, value: 'CAD' }
            ]
          },
          label: {
            type: 'plain_text',
            text: 'Payout Currency'
          }
        },
        {
          type: 'input',
          block_id: 'payout_amount_block',
          element: {
            type: 'plain_text_input',
            action_id: 'payout_amount_action',
            placeholder: {
              type: 'plain_text',
              text: 'Enter Payout Amount'
            }
          },
          label: {
            type: 'plain_text',
            text: 'Payout Amount'
          }
        },
        {
          type: 'input',
          block_id: 'rate_requested_block',
          element: {
            type: 'plain_text_input',
            action_id: 'rate_requested_action',
            placeholder: {
              type: 'plain_text',
              text: 'Enter Rate Requested'
            }
          },
          label: {
            type: 'plain_text',
            text: 'Rate Requested'
          }
        }
      ]
    }

    @slack_client.views_open(trigger_id: trigger_id, view: modal_view)
  rescue Slack::Web::Api::Errors::SlackError => e
    Rails.logger.error("Error opening Slack modal: #{e.message}")
  end

  def respond_to_slack(response_url, message)
    # response = {
    #   text: message,
    #   response_type: 'in_channel'
    # }

    token = ENV['SLACK_BOT_TOKEN']
    response = Faraday.post("https://slack.com/api/chat.postMessage") do |req|
      req.headers['Authorization'] = "Bearer #{token}"
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        channel: 'C07L76LAA9W',
        text: message
      }.to_json
    end
    # @slack_client.chat_postMessage(channel: response_url,text: message)
    # Faraday.post(response_url, response.to_json, 'Content-Type' => 'application/json')
  rescue StandardError => e
    Rails.logger.error("Error responding to Slack via response_url: #{e.message}")
  end

  def get_user_email(user_id)
    user_info = @slack_client.users_info(user: user_id)
    user_info.dig('user', 'profile', 'email')
  rescue Slack::Web::Api::Errors::SlackError => e
    Rails.logger.error("Error fetching user info: #{e.message}")
    nil
  end
end
