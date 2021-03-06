class TagImplicationRequest
  include ActiveModel::Validations

  attr_reader :antecedent_name, :consequent_name, :reason, :tag_implication, :forum_topic, :skip_secondary_validations

  validate :validate_tag_implication
  validate :validate_forum_topic

  def initialize(attributes)
    @antecedent_name = attributes[:antecedent_name].strip.tr(" ", "_")
    @consequent_name = attributes[:consequent_name].strip.tr(" ", "_")
    @reason = attributes[:reason]
    self.skip_secondary_validations = attributes[:skip_secondary_validations]
  end

  def create
    return false if invalid?

    TagImplication.transaction do
      @tag_implication = build_tag_implication
      @tag_implication.save

      @forum_topic = build_forum_topic(@tag_implication.id)
      @forum_topic.save

      @tag_implication.update_attribute(:forum_topic_id, @forum_topic.id)
    end
  end

  def build_tag_implication
    TagImplication.new(
      :antecedent_name => antecedent_name, 
      :consequent_name => consequent_name, 
      :status => "pending", 
      :skip_secondary_validations => skip_secondary_validations
    )
  end

  def build_forum_topic(tag_implication_id)
    ForumTopic.new(
      :title => "Tag implication: #{antecedent_name} -> #{consequent_name}",
      :original_post_attributes => {
        :body => "create implication [[#{antecedent_name}]] -> [[#{consequent_name}]]\n\n\"Link to implication\":/tag_implications?search[id]=#{tag_implication_id}\n\n#{reason}"
      },
      :category_id => 1
    )
  end

  def validate_tag_implication
    ti = @tag_implication || build_tag_implication

    if ti.invalid?
      self.errors.add(:base, ti.errors.full_messages.join("; ")) 
      return false
    end
  end

  def validate_forum_topic
    ft = @forum_topic || build_forum_topic(nil)
    if ft.invalid?
      self.errors.add(:base, ft.errors.full_messages.join("; ")) 
      return false
    end
  end

  def skip_secondary_validations=(v)
    if v == "1" or v == true
      @skip_secondary_validations = true
    else
      @skip_secondary_validations = false
    end
  end
end
