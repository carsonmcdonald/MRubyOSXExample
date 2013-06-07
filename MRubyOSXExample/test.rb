Foo::print("Testing...")
Foo::print("")
Foo::print("1...")
Foo::print("2...")
Foo::print("3...")

Fiber.new {
    Foo::print("In fiber")
}.resume()

puts("puts output")