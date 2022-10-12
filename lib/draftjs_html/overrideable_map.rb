module DraftjsHtml
  class OverrideableMap
    def initialize(defaults = {})
      @map = defaults.dup.transform_keys(&:to_s)
    end

    def with_overrides(overrides)
      @map.merge!((overrides || {}).transform_keys(&:to_s))
      self
    end

    def with_default(default)
      @default = default
      self
    end

    def value_of!(key)
      @map.fetch(key.to_s)
    end

    def value_of(key)
      @map.fetch(key.to_s, @default)
    end
  end
end