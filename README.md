# Dada

(pronounced like the art movement)

A total recursion scheme library for [Dhall](https://github.com/dhall-lang/dhall-lang/).

## Comparisons

### [Iaia](https://github.com/sellout/Iaia), [Turtles](https://github.com/sellout/turtles), and [Yaya](https://github.com/sellout/yaya)

These three libraries (plus, this one – Dada) form a family of recursion scheme libraries across various languages. There are differences, due to the languages, but overall they are designed to be very similar.

In the case of Dada, it offers _no_ partial operations (unlike the other three), because Dhall provides no way to define them. Also, since all instances are explicit and all names are qualified, the higher-order operations have the same names as the proper ones.
