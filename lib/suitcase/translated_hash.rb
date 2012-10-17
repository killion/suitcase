class TranslatedHash < Hash
  @root = nil
  
  def initialize( object )
    super
    update object
  end
  
  def self.translation_root( name )
    raise "translation_root should only used once for each class" if @root
    @root = name.to_s.split( '.' )
  end
  
  def self.translate( name, options={} )
    raise "translate needs a non-blank argument" if name.nil? or name.empty?
    raise "translate :into option can't be blank" if options.include?(:into) and options[:into].empty?
    
    keys = name.to_s.split( '.' )
    keys.unshift(@root).flatten! if @root
    accessor = options.include?( :into ) ? options[:into] : name
    
    translator = options.include?( :using ) ? options[:using] : lambda{ |x| x }
    raise "translate :using option must be a lambda" unless translator.respond_to? :call
    
    class_eval do
      define_method accessor do
        translator.call( keys.inject( self ){ |hash, key| hash[key] } )
      end
    end
  end
end