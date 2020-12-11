package bake

command: {
  image: #Dubo & {
    args: {
      BUILD_TITLE: "Registry"
      BUILD_DESCRIPTION: "A dubo image for Registry based on \(args.DEBOOTSTRAP_SUITE) (\(args.DEBOOTSTRAP_DATE))"
    }
  }
}
