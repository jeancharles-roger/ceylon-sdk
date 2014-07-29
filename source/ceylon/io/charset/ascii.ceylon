import ceylon.io.buffer { ByteBuffer, CharacterBuffer }

"Implementation of the ASCII character set. 
 See [the ASCII specification](http://tools.ietf.org/html/rfc20) for more information."
by("Stéphane Épardaud")
shared object ascii satisfies Charset {
    
    "Returns `US-ASCII`. This deviates a bit from 
     [the internet registry](http://www.iana.org/assignments/character-sets) which defines it as
     `ANSI_X3.4-1968`, whereas we use its _preferred MIME name_ because that is more widely known."
    shared actual String name = "US-ASCII";

    "The set of aliases, as defined by 
     [the internet registry](http://www.iana.org/assignments/character-sets). Note that
     because we use the _preferred MIME name_ (`US-ASCII`) as [[name]], we include the
     official character set name `ANSI_X3.4-1968` in the aliases, thereby deviating
     from the spec."
    shared actual String[] aliases = [
        "ANSI_X3.4-1968",
        "iso-ir-6",
        "ANSI_X3.4-1986",
        "ISO_646.irv:1991",
        "ISO646-US",
        "ASCII",
        "us",
        "IBM367",
        "cp367"
    ];

    "Returns 1."
    shared actual Integer minimumBytesPerCharacter = 1;
    
    "Returns 1."
    shared actual Integer maximumBytesPerCharacter = 1;

    "Returns 1."
    shared actual Integer averageBytesPerCharacter = 1;

    "Returns a new ASCII decoder"
    shared actual Decoder newDecoder()
            => ASCIIDecoder(this);

    "Returns a new ASCII encoder"
    shared actual Encoder newEncoder()
            => ASCIIEncoder(this);
}

class ASCIIDecoder(charset) extends AbstractDecoder() {
    shared actual Charset charset;

    shared actual void decode(ByteBuffer buffer) {
        for(byte in buffer){
            if(byte.signed < 0){
                // FIXME: type
                throw Exception("Invalid ASCII byte value: ``byte``");
            }
            builder.appendCharacter(byte.signed.character);
        }
    }
}

class ASCIIEncoder(charset) satisfies Encoder {
    shared actual Charset charset;
    
    shared actual void encode(CharacterBuffer input, ByteBuffer output) {
        // give up if there's no input or no room for output
        while(input.hasAvailable && output.hasAvailable){
            value char = input.get().integer;
            if(char > 127){
                // FIXME: type
                throw Exception("Invalid ASCII byte value: ``char``");
            }
            output.put(char.byte);
        }
    }

}

