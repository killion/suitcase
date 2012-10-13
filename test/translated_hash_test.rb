require "minitest_helper"

describe TranslatedHash do
  describe "with one argument" do
    class LikeAttribute < TranslatedHash
      translate :name
    end
    
    subject { LikeAttribute.new("name" => "Cowboy") }
    
    describe "should make a getter" do
      it { subject.must_respond_to :name }
      it { subject.name.must_equal "Cowboy" }
    end
    
    # describe "should make a setter" do
    #   it { subject.must_respond_to :name= }
    #   it "should allow assignment" do
    #     subject.name = "Steampunker"
    #     subject.name.must_equal "Steampunker"
    #   end
    # end
  end
  
  describe "with one argument that represents nested keys" do
    class LikeNestedAttribute < TranslatedHash
      translate "raw.user.data.dob", :into => :date_of_birth
    end
    
    subject do
      LikeNestedAttribute.new({
        "raw" => {
          "user" => {
            "data" => {
              "dob" => "1969-06-27"
            }
          }
        }
      })
    end
    
    describe "should make a getter" do
      it { subject.must_respond_to :date_of_birth }
      it { subject.date_of_birth.must_equal "1969-06-27" }
    end
  end
  
  describe "with :into" do
    class LikeRenamedAttribute < TranslatedHash
      translate :FullName, :into => :name
    end

    subject { LikeRenamedAttribute.new("FullName" => "Outlaw") }
    
    describe "should make a getter" do
      it { subject.must_respond_to :name }
      it { subject.name.must_equal "Outlaw" }
    end
  end
  
  describe "with :using" do
    class LikeProcessedAttribute < TranslatedHash
      translate :angry_name, :using => lambda { |name_value| name_value.upcase }
    end

    subject { LikeProcessedAttribute.new("angry_name" => "angry tony") }
    
    describe "should make a getter" do
      it { subject.must_respond_to :angry_name }
      it { subject.angry_name.must_equal "ANGRY TONY" }
    end
  end
  
  describe "with :using and :into" do
    class LikeRenamedAndProcessedAttribute < TranslatedHash
      translate :FirstName, :into => :proper_name, :using => lambda { |name_value| name_value.capitalize }
    end

    subject { LikeRenamedAndProcessedAttribute.new("FirstName" => "oliver") }
    
    describe "should make a getter" do
      it { subject.must_respond_to :proper_name }
      it { subject.proper_name.must_equal "Oliver" }
    end
  end
end