module Brotli
  @[Link(ldflags: "`command -v pkg-config > /dev/null && pkg-config --libs libbrotlicommon libbrotlidec libbrotlienc 2> /dev/null|| printf %s '--llbrotlicommon --llbrotlidec --llbrotlienc'`")]

  lib LibBrotli
    alias Uint8T = UInt8
    alias Uint32T = LibC::UInt
    TRUE                  =  1
    FALSE                 =  0
    MIN_WINDOW_BITS       = 10
    MAX_WINDOW_BITS       = 24
    LARGE_MAX_WINDOW_BITS = 30
    MIN_INPUT_BLOCK_BITS  = 16
    MAX_INPUT_BLOCK_BITS  = 24
    MIN_QUALITY           =  0
    MAX_QUALITY           = 11
    DEFAULT_QUALITY       = 11
    DEFAULT_WINDOW        = 22

    alias DecoderStateStruct = Void

    fun decoder_set_parameter = BrotliDecoderSetParameter(state : DecoderState, param : DecoderParameter, value : Uint32T) : LibC::Int
    type DecoderState = Void*
    enum DecoderParameter
      DecoderParamDisableRingBufferReallocation = 0
      DecoderParamLargeWindow                   = 1
    end

    fun decoder_create_instance = BrotliDecoderCreateInstance(alloc_func : BrotliAllocFunc, free_func : BrotliFreeFunc, opaque : Void*) : DecoderState
    alias BrotliAllocFunc = (Void*, LibC::SizeT -> Void*)
    alias BrotliFreeFunc = (Void*, Void* -> Void)
    fun decoder_destroy_instance = BrotliDecoderDestroyInstance(state : DecoderState)
    fun decoder_decompress = BrotliDecoderDecompress(encoded_size : LibC::SizeT, encoded_buffer : Uint8T*, decoded_size : LibC::SizeT*, decoded_buffer : Uint8T*) : DecoderResult

    enum DecoderResult
      DecoderResultError           = 0
      DecoderResultSuccess         = 1
      DecoderResultNeedsMoreInput  = 2
      DecoderResultNeedsMoreOutput = 3
    end
    fun decoder_decompress_stream = BrotliDecoderDecompressStream(state : DecoderState, available_in : LibC::SizeT*, next_in : Uint8T**, available_out : LibC::SizeT*, next_out : Uint8T**, total_out : LibC::SizeT*) : DecoderResult
    fun decoder_has_more_output = BrotliDecoderHasMoreOutput(state : DecoderState) : LibC::Int
    fun decoder_take_output = BrotliDecoderTakeOutput(state : DecoderState, size : LibC::SizeT*) : Uint8T*
    fun decoder_is_used = BrotliDecoderIsUsed(state : DecoderState) : LibC::Int
    fun decoder_is_finished = BrotliDecoderIsFinished(state : DecoderState) : LibC::Int
    fun decoder_get_error_code = BrotliDecoderGetErrorCode(state : DecoderState) : DecoderErrorCode
    enum DecoderErrorCode : Int64
      DecoderNoError                          =   0
      DecoderSuccess                          =   1
      DecoderNeedsMoreInput                   =   2
      DecoderNeedsMoreOutput                  =   3
      DecoderErrorFormatExuberantNibble       =  -1
      DecoderErrorFormatReserved              =  -2
      DecoderErrorFormatExuberantMetaNibble   =  -3
      DecoderErrorFormatSimpleHuffmanAlphabet =  -4
      DecoderErrorFormatSimpleHuffmanSame     =  -5
      DecoderErrorFormatClSpace               =  -6
      DecoderErrorFormatHuffmanSpace          =  -7
      DecoderErrorFormatContextMapRepeat      =  -8
      DecoderErrorFormatBlockLength1          =  -9
      DecoderErrorFormatBlockLength2          = -10
      DecoderErrorFormatTransform             = -11
      DecoderErrorFormatDictionary            = -12
      DecoderErrorFormatWindowBits            = -13
      DecoderErrorFormatPadding1              = -14
      DecoderErrorFormatPadding2              = -15
      DecoderErrorFormatDistance              = -16
      DecoderErrorDictionaryNotSet            = -19
      DecoderErrorInvalidArguments            = -20
      DecoderErrorAllocContextModes           = -21
      DecoderErrorAllocTreeGroups             = -22
      DecoderErrorAllocContextMap             = -25
      DecoderErrorAllocRingBuffer1            = -26
      DecoderErrorAllocRingBuffer2            = -27
      DecoderErrorAllocBlockTypeTrees         = -30
      DecoderErrorUnreachable                 = -31

      def to_s
        String.new LibBrotli.decoder_error_string(self)
      end
    end
    fun decoder_error_string = BrotliDecoderErrorString(c : DecoderErrorCode) : LibC::Char*
    fun decoder_version = BrotliDecoderVersion : Uint32T
    alias EncoderStateStruct = Void
    fun encoder_set_parameter = BrotliEncoderSetParameter(state : EncoderState, param : EncoderParameter, value : Uint32T) : LibC::Int
    type EncoderState = Void*
    enum EncoderParameter
      ParamMode                          = 0
      ParamQuality                       = 1
      ParamLgwin                         = 2
      ParamLgblock                       = 3
      ParamDisableLiteralContextModeling = 4
      ParamSizeHint                      = 5
      ParamLargeWindow                   = 6
      ParamNpostfix                      = 7
      ParamNdirect                       = 8
    end
    fun encoder_create_instance = BrotliEncoderCreateInstance(alloc_func : BrotliAllocFunc, free_func : BrotliFreeFunc, opaque : Void*) : EncoderState
    fun encoder_destroy_instance = BrotliEncoderDestroyInstance(state : EncoderState)
    fun encoder_max_compressed_size = BrotliEncoderMaxCompressedSize(input_size : LibC::SizeT) : LibC::SizeT
    fun encoder_compress = BrotliEncoderCompress(quality : LibC::Int, lgwin : LibC::Int, mode : EncoderMode, input_size : LibC::SizeT, input_buffer : Uint8T*, encoded_size : LibC::SizeT*, encoded_buffer : Uint8T*) : LibC::Int
    enum EncoderMode
      ModeGeneric = 0
      ModeText    = 1
      ModeFont    = 2
    end
    fun encoder_compress_stream = BrotliEncoderCompressStream(state : EncoderState, op : EncoderOperation, available_in : LibC::SizeT*, next_in : Uint8T**, available_out : LibC::SizeT*, next_out : Uint8T**, total_out : LibC::SizeT*) : LibC::Int
    enum EncoderOperation
      OperationProcess      = 0
      OperationFlush        = 1
      OperationFinish       = 2
      OperationEmitMetadata = 3
    end
    fun encoder_is_finished = BrotliEncoderIsFinished(state : EncoderState) : LibC::Int
    fun encoder_has_more_output = BrotliEncoderHasMoreOutput(state : EncoderState) : LibC::Int
    fun encoder_take_output = BrotliEncoderTakeOutput(state : EncoderState, size : LibC::SizeT*) : Uint8T*
    fun encoder_version = BrotliEncoderVersion : Uint32T
  end
end
