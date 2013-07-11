class PhoneNumber
  def initialize(number)
    @number = self.class.to_e164 number
  end

  def to_e164
    @number
  end

  def to_human
    # Assume we're in E.164 format
    if @number.length != 12
      # It's not a US number!
      return @number
    end
    area = @number[2,3]
    exchange = @number[5,3]
    subscriber = @number[8,4]
    "(#{area}) #{exchange}-#{subscriber}"
  end

  def to_s
    @number
  end

  private
  class << self
    def to_e164(number)
      cleaned = number.gsub(/[^0-9]/, '')
      if cleaned.length < 11 #15555551212
        cleaned = "1#{cleaned}"
      end
      "+#{cleaned}"
    end
  end
end