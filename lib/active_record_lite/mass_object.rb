class MassObject
  def self.my_attr_accessible(*attributes)
    attributes.each do |attribute|
      define_method("#{attribute.to_s}=") do |value|
        self.instance_variable_set("@#{attribute.to_s}", value)
      end

      define_method("#{attribute.to_s}") do
        self.instance_variable_get("@#{attribute.to_s}")
      end
    end
    self.instance_variable_set("@attributes", attributes)
  end

  def self.attributes
    self.instance_variable_get("@attributes")
  end

  def self.parse_all(results)
    results.map { |result_hash| self.new(result_hash) }
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      if self.class.attributes.send(:include?, attr_name.to_sym)
        send("#{attr_name.to_s}=", value)
      else
        raise "mass assignment to unregistered attribute #{attr_name}"
      end
    end

  end
end


if __FILE__ == $PROGRAM_NAME

  class MyClass < MassObject
    my_attr_accessible :x, :y
  end

  mc = MyClass.new(:x => :x_val, :y => :y_val)
  p mc.x
  p mc.y

end
