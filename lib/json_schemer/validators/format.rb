# frozen_string_literal: true
module JSONSchemer
  module Validators
    class Format < Validator
      # this is no good
      EMAIL_REGEX = /\A[^@\s]+@([\p{L}\d-]+\.)+[\p{L}\d\-]{2,}\z/i.freeze
      LABEL_REGEX_STRING = '\p{L}([\p{L}\p{N}\-]*[\p{L}\p{N}])?'
      HOSTNAME_REGEX = /\A(#{LABEL_REGEX_STRING}\.)*#{LABEL_REGEX_STRING}\z/i.freeze
      JSON_POINTER_REGEX_STRING = '(\/([^~\/]|~[01])*)*'
      JSON_POINTER_REGEX = /\A#{JSON_POINTER_REGEX_STRING}\z/.freeze
      RELATIVE_JSON_POINTER_REGEX = /\A(0|[1-9]\d*)(#|#{JSON_POINTER_REGEX_STRING})?\z/.freeze

      # https://github.com/ruby-rdf/rdf

      # IRI components
      UCSCHAR = Regexp.compile(<<-EOS.gsub(/\s+/, ''))
        [\\u00A0-\\uD7FF]|[\\uF900-\\uFDCF]|[\\uFDF0-\\uFFEF]|
        [\\u{10000}-\\u{1FFFD}]|[\\u{20000}-\\u{2FFFD}]|[\\u{30000}-\\u{3FFFD}]|
        [\\u{40000}-\\u{4FFFD}]|[\\u{50000}-\\u{5FFFD}]|[\\u{60000}-\\u{6FFFD}]|
        [\\u{70000}-\\u{7FFFD}]|[\\u{80000}-\\u{8FFFD}]|[\\u{90000}-\\u{9FFFD}]|
        [\\u{A0000}-\\u{AFFFD}]|[\\u{B0000}-\\u{BFFFD}]|[\\u{C0000}-\\u{CFFFD}]|
        [\\u{D0000}-\\u{DFFFD}]|[\\u{E1000}-\\u{EFFFD}]
      EOS
      IPRIVATE = Regexp.compile("[\\uE000-\\uF8FF]|[\\u{F0000}-\\u{FFFFD}]|[\\u100000-\\u10FFFD]").freeze
      SCHEME = Regexp.compile("[A-Za-z](?:[A-Za-z0-9+-\.])*").freeze
      PORT = Regexp.compile("[0-9]*").freeze
      IP_LITERAL = Regexp.compile("\\[[0-9A-Fa-f:\\.]*\\]").freeze  # Simplified, no IPvFuture
      PCT_ENCODED = Regexp.compile("%[0-9A-Fa-f][0-9A-Fa-f]").freeze
      GEN_DELIMS = Regexp.compile("[:/\\?\\#\\[\\]@]").freeze
      SUB_DELIMS = Regexp.compile("[!\\$&'\\(\\)\\*\\+,;=]").freeze
      RESERVED = Regexp.compile("(?:#{GEN_DELIMS}|#{SUB_DELIMS})").freeze
      UNRESERVED = Regexp.compile("[A-Za-z0-9\._~-]").freeze

      IUNRESERVED = Regexp.compile("[A-Za-z0-9\._~-]|#{UCSCHAR}").freeze

      IPCHAR = Regexp.compile("(?:#{IUNRESERVED}|#{PCT_ENCODED}|#{SUB_DELIMS}|:|@)").freeze

      IQUERY = Regexp.compile("(?:#{IPCHAR}|#{IPRIVATE}|/|\\?)*").freeze

      IFRAGMENT = Regexp.compile("(?:#{IPCHAR}|/|\\?)*").freeze.freeze

      ISEGMENT = Regexp.compile("(?:#{IPCHAR})*").freeze
      ISEGMENT_NZ = Regexp.compile("(?:#{IPCHAR})+").freeze
      ISEGMENT_NZ_NC = Regexp.compile("(?:(?:#{IUNRESERVED})|(?:#{PCT_ENCODED})|(?:#{SUB_DELIMS})|@)+").freeze

      IPATH_ABEMPTY = Regexp.compile("(?:/#{ISEGMENT})*").freeze
      IPATH_ABSOLUTE = Regexp.compile("/(?:(?:#{ISEGMENT_NZ})(/#{ISEGMENT})*)?").freeze
      IPATH_NOSCHEME = Regexp.compile("(?:#{ISEGMENT_NZ_NC})(?:/#{ISEGMENT})*").freeze
      IPATH_ROOTLESS = Regexp.compile("(?:#{ISEGMENT_NZ})(?:/#{ISEGMENT})*").freeze
      IPATH_EMPTY = Regexp.compile("").freeze

      IREG_NAME   = Regexp.compile("(?:(?:#{IUNRESERVED})|(?:#{PCT_ENCODED})|(?:#{SUB_DELIMS}))*").freeze
      IHOST = Regexp.compile("(?:#{IP_LITERAL})|(?:#{IREG_NAME})").freeze
      IUSERINFO = Regexp.compile("(?:(?:#{IUNRESERVED})|(?:#{PCT_ENCODED})|(?:#{SUB_DELIMS})|:)*").freeze
      IAUTHORITY = Regexp.compile("(?:#{IUSERINFO}@)?#{IHOST}(?::#{PORT})?").freeze

      IRELATIVE_PART = Regexp.compile("(?:(?://#{IAUTHORITY}(?:#{IPATH_ABEMPTY}))|(?:#{IPATH_ABSOLUTE})|(?:#{IPATH_NOSCHEME})|(?:#{IPATH_EMPTY}))").freeze
      IRELATIVE_REF = Regexp.compile("^#{IRELATIVE_PART}(?:\\?#{IQUERY})?(?:\\##{IFRAGMENT})?$").freeze

      IHIER_PART = Regexp.compile("(?:(?://#{IAUTHORITY}#{IPATH_ABEMPTY})|(?:#{IPATH_ABSOLUTE})|(?:#{IPATH_ROOTLESS})|(?:#{IPATH_EMPTY}))").freeze
      IRI = Regexp.compile("^#{SCHEME}:(?:#{IHIER_PART})(?:\\?#{IQUERY})?(?:\\##{IFRAGMENT})?$").freeze

      def valid?(instance, instance_location)
        return true unless instance.is_a?(String)

        case value
        when 'date-time'
          valid_date_time?(instance)
        when 'date'
          valid_date_time?("#{instance}T04:05:06.123456789+07:00")
        when 'time'
          valid_date_time?("2001-02-03T#{instance}")
        when 'email'
          instance.ascii_only? && valid_email?(instance)
        when 'idn-email'
          valid_email?(instance)
        when 'hostname'
          instance.ascii_only? && valid_hostname?(instance)
        when 'idn-hostname'
          valid_hostname?(instance)
        when 'ipv4'
          valid_ip?(instance, :v4)
        when 'ipv6'
          valid_ip?(instance, :v6)
        when 'uri'
          instance.ascii_only? && valid_iri?(instance)
        when 'uri-reference'
          instance.ascii_only? && (valid_iri?(instance) || valid_iri_reference?(instance))
        when 'iri'
          valid_iri?(instance)
        when 'iri-reference'
          valid_iri?(instance) || valid_iri_reference?(instance)
        when 'uri-template'
          valid_uri_template?(instance)
        when 'json-pointer'
          valid_json_pointer?(instance)
        when 'relative-json-pointer'
          valid_relative_json_pointer?(instance)
        when 'regex'
          EcmaReValidator.valid?(instance)
        end
      end

    private

      def valid_json?(instance)
        JSON.parse(instance)
        true
      rescue JSON::ParserError
        false
      end

      def valid_date_time?(instance)
        DateTime.rfc3339(instance)
        true
      rescue ArgumentError => e
        raise e unless e.message == 'invalid date'
        false
      end

      def valid_email?(instance)
        !!(EMAIL_REGEX =~ instance)
      end

      def valid_hostname?(instance)
        !!(HOSTNAME_REGEX =~ instance && instance.split('.').all? { |label| label.size <= 63 })
      end

      def valid_ip?(instance, type)
        ip_address = IPAddr.new(instance)
        type == :v4 ? ip_address.ipv4? : ip_address.ipv6?
      rescue IPAddr::InvalidAddressError
        false
      end

      def valid_iri?(instance)
        !!(IRI =~ instance)
      end

      def valid_iri_reference?(instance)
        !!(IRELATIVE_REF =~ instance)
      end

      def valid_uri_template?(instance)
        URITemplate.new(instance)
        true
      rescue URITemplate::Invalid
        false
      end

      def valid_json_pointer?(instance)
        !!(JSON_POINTER_REGEX =~ instance)
      end

      def valid_relative_json_pointer?(instance)
        !!(RELATIVE_JSON_POINTER_REGEX =~ instance)
      end
    end
  end
end
