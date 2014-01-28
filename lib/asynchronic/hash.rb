class Hash
  def with_indiferent_access
    HashWithIndiferentAccess.new self
  end
end

class HashWithIndiferentAccess < Hash

  def initialize(hash=nil)
    merge! hash if hash
  end

  def [](key)
    if key?(key) || !transformable_key?(key)
      super
    else
      super transform_key(key)
    end
  end

  private

  def transformable_key?(key)
    key.is_a?(String) || key.is_a?(Symbol)
  end

  def transform_key(key)
    key.is_a?(String) ? key.to_sym : key.to_s
  end

end