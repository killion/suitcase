class TranslatedHash < Hash
  def initialize( object )
    super
    update object
  end
  
  def self.translate( name, options={} )
    raise "translate needs a non-blank argument" if name.nil? or name.empty?
    raise "translate :into option can't be blank" if options.include?(:into) and options[:into].empty?
    
    keys = name.to_s.split( '.' )
    accessor = options.include?( :into ) ? options[:into] : name
    
    if keys.size > 1 and !options.include?(:into)
      raise "translate :into option must be specified when using dot notation" 
    end
    
    translator = options.include?( :using ) ? options[:using] : lambda{ |x| x }
    raise "translate :using option must be a lambda" unless translator.respond_to? :call
    
    class_eval do
      define_method accessor do
        translator.call( keys.inject( self ){ |hash, key| hash[key] } )
      end
    end
  end
end