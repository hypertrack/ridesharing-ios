alias f := format
alias i := install
alias l := lint

format:
    swiftformat . --swiftversion 4.2

install:
    pod install

lint:
    swiftlint lint
