require 'pp'
require 'digest'
require 'base64'
require 'openssl'

## 3rd party gems
require 'digest/sha3'  # e.g. keccak (original submission/proposal NOT official sha3)
## see https://rubygems.org/gems/digest-sha3-patched
##     https://github.com/teamhedge/digest-sha3-ruby



## our own code
require 'crypto-lite/version'    # note: let version always go first



module Crypto

  ## check if it is a hex (string)
  ##  - allow optiona 0x or 0X  and allow abcdef and ABCDEF
  HEX_RE = /\A(?:0x)?[0-9a-f]+\z/i



  def self.message( input )  ## convert input to (binary) string
    input_type = if input.is_a?( String )
                  "#{input.class.name}/#{input.encoding}"
                 else
                  input.class.name
                 end
    puts "  input: #{input} (#{input_type})"

    message = if input.is_a?( Integer )  ## assume byte if single (unsigned) integer
                raise ArgumentError, "expected unsigned byte (0-255) - got #{input} (0x#{input.to_s(16)}) - can't pack negative number; sorry"   if input < 0
                ## note: pack -  H (String) => hex string (high nibble first)
                ## todo/check: is there a better way to convert integer number to (binary) string!!!
                [input.to_s(16)].pack('H*')
              else  ## assume (binary) string
                input
              end

    bytes = message.bytes
    bin   = bytes.map {|byte| byte.to_s(2).rjust(8, "0")}.join( ' ' )
    hex   = bytes.map {|byte| byte.to_s(16).rjust(2, "0")}.join( ' ' )
    puts "  #{pluralize( bytes.size, 'byte')}:  #{bytes.inspect}"
    puts "  binary: #{bin}"
    puts "  hex:    #{hex}"

    message
  end



  def self.keccak256bin( input )
    message = message( input )   ## "normalize" / convert to (binary) string
    Digest::SHA3.digest( message, 256 )
  end

  def self.keccak256( input )
    input = hex_to_bin_automagic( input )  ## add automagic hex (string) to bin (string) check - why? why not?
    keccak256bin( input ).unpack( 'H*' )[0]
  end



  def self.rmd160bin( input )
    message = message( input )   ## "normalize" / convert to (binary) string
    Digest::RMD160.digest( message )
  end

  def self.rmd160( input )
    input = hex_to_bin_automagic( input )  ## add automagic hex (string) to bin (string) check - why? why not?
    rmd160bin( input ).unpack( 'H*' )[0]
  end
  ## todo/fix: add alias RIPEMD160 - why? why not?



  def self.sha256bin( input, engine=nil )   ## todo/check: add alias sha256b or such to - why? why not?
       message = message( input )  ## "normalize" / convert to (binary) string

       if engine && ['openssl'].include?( engine.to_s.downcase )
         puts "  engine: #{engine}"
         digest = OpenSSL::Digest::SHA256.new
         digest.update( message )
         digest.digest
       else  ## use "built-in" hash function from digest module
         Digest::SHA256.digest( message )
       end
  end

  def self.sha256( input, engine=nil )
    input = hex_to_bin_automagic( input )  ## add automagic hex (string) to bin (string) check - why? why not?
    sha256bin( input, engine ).unpack( 'H*' )[0]
  end


  def self.sha256hex( input, engine=nil )  ## convenience helper - lets you pass in hex string
    raise ArgumentError, "expected hex string (0-9a-f) - got >#{input}< - can't pack string; sorry"   unless input =~ HEX_RE

    input = strip0x( input )  ##  check if input starts with 0x or 0X if yes - (auto-)cut off!!!!!
    sha256bin( [input].pack( 'H*' ), engine ).unpack( 'H*' )[0]
  end



  ####
  ## helper
  # def hash160( pubkey )
  #  binary    = [pubkey].pack( "H*" )       # Convert to binary first before hashing
  #  sha256    = Digest::SHA256.digest( binary )
  #  ripemd160 = Digest::RMD160.digest( sha256 )
  #              ripemd160.unpack( "H*" )[0]    # Convert back to hex
  # end

  def self.hash160bin( input )
    message = message( input )   ## "normalize" / convert to (binary) string

    rmd160bin(sha256bin( message ))
  end

  def self.hash160( input )
    input = hex_to_bin_automagic( input )  ## add automagic hex (string) to bin (string) check - why? why not?
    hash160bin( input ).unpack( 'H*' )[0]
  end

  def self.hash160hex( input )  ## convenience helper - lets you pass in hex string
    raise ArgumentError, "expected hex string (0-9a-f) - got >#{input}< - can't pack string; sorry"   unless input =~ HEX_RE

    input = strip0x( input )  ##  check if input starts with 0x or 0X if yes - (auto-)cut off!!!!!
    hash160bin( [input].pack( 'H*' ) ).unpack( 'H*' )[0]
  end



  def self.hash256bin( input )
    message = message( input )   ## "normalize" / convert to (binary) string

    sha256bin(sha256bin( message ))
  end

  def self.hash256( input )
    input = hex_to_bin_automagic( input )  ## add automagic hex (string) to bin (string) check - why? why not?
    hash256bin( input ).unpack( 'H*' )[0]
  end

  def self.hash256hex( input )  ## convenience helper - lets you pass in hex string
    raise ArgumentError, "expected hex string (0-9a-f) - got >#{input}< - can't pack string; sorry"   unless input =~ HEX_RE

    input = strip0x( input )  ##  check if input starts with 0x or 0X if yes - (auto-)cut off!!!!!
    hash256bin( [input].pack( 'H*' ) ).unpack( "H*" )[0]
  end


  ########
  # more helpers
  def self.hex_to_bin_automagic( input )
    ## todo/check/fix: add configure setting to turn off automagic - why? why not?
     if input.is_a?( String ) && input =~ HEX_RE
        if input[0,2] == '0x' || input[0,2] == '0X'
          ## starting with 0x or 0X always assume hex string for now - why? why not?
          input = input[2..-1]
          [input].pack( 'H*' )
        elsif input.size >= 10
          ## note: hex heuristic!!
          ##   for now assumes string MUST have more than 10 digits to qualify!!!
          [input].pack( 'H*' )
        else
          input ## pass through as is!!! (e.g.   a, abc, etc.)
        end
     else
          input  ## pass through as is
     end
  end


  def self.strip0x( str )    ## todo/check: add alias e.g. strip_hex_prefix or such - why? why not?
    (str[0,2] == '0x' || str[0,2] == '0X') ?  str[2..-1] : str
  end

  def self.hex_to_bin( str )
    str = strip0x( str )  ##  check if input starts with 0x or 0X if yes - (auto-)cut off!!!!!
    [str].pack( 'H*' )
  end

  def self.pluralize( count, noun )
     count == 1 ? "#{count} #{noun}" : "#{count} #{noun}s"
  end




module RSA
  def self.generate_keys  ## todo/check: add a generate alias - why? why not?
    key_pair = OpenSSL::PKey::RSA.new( 2048 )
    private_key = key_pair.export
    public_key  = key_pair.public_key.export

    [private_key, public_key]
  end


  def self.sign( plaintext, private_key )
    private_key = OpenSSL::PKey::RSA.new( private_key ) ## note: convert/wrap into to obj from exported text format
    Base64.encode64( private_key.private_encrypt( plaintext ))
  end

  def self.decrypt( ciphertext, public_key )
    public_key = OpenSSL::PKey::RSA.new( public_key )  ## note: convert/wrap into to obj from exported text format
    public_key.public_decrypt( Base64.decode64( ciphertext ))
  end


  def self.valid_signature?( plaintext, ciphertext, public_key )
    plaintext == decrypt( ciphertext, public_key )
  end
end # module RSA
end # module Crypto




## add convenience "top-level" helpers
def sha256( input, engine=nil )    Crypto.sha256( input, engine ); end
def sha256hex( input, engine=nil ) Crypto.sha256hex( input, engine ); end

def keccak256( input )    Crypto.keccak256( input ); end

def rmd160( input )    Crypto.rmd160( input ); end

def hash160( input )    Crypto.hash160( input ); end
def hash160hex( input ) Crypto.hash160hex( input ); end

def hash256( input )    Crypto.hash256( input ); end
def hash256hex( input ) Crypto.hash256hex( input ); end


RSA = Crypto::RSA






puts CryptoLite.banner    ## say hello