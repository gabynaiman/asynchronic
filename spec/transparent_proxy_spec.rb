require 'minitest_helper'

describe Asynchronic::TransparentProxy do

  it 'Transparent' do
    proxy = Asynchronic::TransparentProxy.new 1

    proxy.must_equal 1
    (proxy + 1).must_equal 2
    proxy.class.must_equal Fixnum
    proxy.inspect.must_equal 1.inspect
    proxy.methods.must_equal proxy.proxy_methods | 1.methods
  end
  
  it 'Proxy methods' do
    proxy = Asynchronic::TransparentProxy.new 1
    
    proxy.must_be :proxy?
    proxy.proxy_class.must_equal Asynchronic::TransparentProxy
    proxy.proxy_inspect.must_match /#<Asynchronic::TransparentProxy @object=1>/
    proxy.proxy_methods.must_include_all [:__send__, :object_id, :tap]
    proxy.must_respond_to :proxy_respond_to?
  end

  it 'Subclass' do
    class NumberProxy < Asynchronic::TransparentProxy
      def to_letters
        'one'
      end
    end

    proxy = NumberProxy.new 1
    proxy.to_letters.must_equal 'one' 
  end

end