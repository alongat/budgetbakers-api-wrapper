module Budgetbakers
  class TokenNotFoundException < StandardError; end
  class MissingParams < StandardError; end
  class InvalidResponse < StandardError; end
  class AccountNotFound < StandardError; end
  class UnknownCurrency < StandardError; end
end