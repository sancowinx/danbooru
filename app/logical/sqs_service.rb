class SqsService
  attr_reader :url

  def initialize(url)
    @url = url
  end

  def send_message(string, options = {})
    return unless Danbooru.config.aws_sqs_enabled?

    sqs.send_message(
      options.merge(
        message_body: string,
        queue_url: url
      )
    )
  end

private

  def sqs
    @sqs ||= begin
      credentials = Aws::Credentials.new(
        Danbooru.config.aws_access_key_id,
        Danbooru.config.aws_secret_access_key
      )
      Aws::SQS::Client.new(
        credentials: credentials,
        region: Danbooru.config.aws_sqs_region
      )
    end
  end
end
