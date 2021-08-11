package cake

import (
	"duponey.cloud/scullery"
	"duponey.cloud/buildkit/types"
	"strings"
)

			// XXX this is really environment instead righty?
			// This to specify if a offband repo is available
			//TARGET_REPOSITORY: #Secret & {
			//	content: "https://apt-cache.local/archive/debian/" + strings.Replace(args.TARGET_DATE, "-", "", -1)
			//}
hooks: {
	context: string @tag(from_context, type=string)
}


cakes: {
  linux: scullery.#Cake & {
		recipe: {
			input: {
				dockerfile: "Dockerfile.linux"
			}
			process: {
				target: "runtime-tools"
				platforms: types.#Platforms | * [
					types.#Platforms.#AMD64,
					types.#Platforms.#ARM64,
					types.#Platforms.#I386,
					types.#Platforms.#V7,
					types.#Platforms.#V6,
					types.#Platforms.#PPC64LE,
				]
			}
			// XXX Broke recently
			// Possibly aggressive CFLAGS - buildctl and terraform are dead
			// types.#Platforms.#S390X,
			output: {
				images: {
					names: [...string] | * ["tools"],
					tags: [...string] | * ["linux-latest"]
				}
			}
			metadata: {
				title: "Dubo Tools for Linux",
				description: "Runtime utils: goello, caddy, healthcheckers",
			}
		}
  }

	linux_dev: scullery.#Cake & {
		recipe: {
			input: {
				dockerfile: "Dockerfile.linux"
			}
			process: {
				target: "build-tools"
				platforms: types.#Platforms | * [
					types.#Platforms.#AMD64,
					types.#Platforms.#ARM64,
					types.#Platforms.#I386,
					types.#Platforms.#V7,
					types.#Platforms.#V6,
					types.#Platforms.#PPC64LE,
				]
			}
			// XXX Broke recently
			// Possibly aggressive CFLAGS - buildctl and terraform are dead
			// types.#Platforms.#S390X,
			output: {
				images: {
					names: [...string] | * ["tools"],
					tags: [...string] | * ["linux-dev-latest"]
				}
			}
			metadata: {
				title: "Dubo Tools for Linux",
				description: "Dev tools collection: cue, dagger, buildctl, etc",
			}
		}
  }

	// This one processes a local SDK, typically on a mac (or somewhere the SDK is present), targets only the current platform
	// and export a tarball locally without pushing anything
	// Making it push the SDK would probably violate Apple terms of redistribution, so...

  sdk: scullery.#Cake & {
		recipe: {
			input: {
				dockerfile: "Dockerfile.macos"
				// Point this to the folder where MacOSX*XYZ*.sdk live
				// context: IJ
				// Because of the way defaults work, this is the only way
				if hooks.context == _|_ { context: "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs" }
				if hooks.context != _|_ { context: hooks.context }
			}
			process: {
				target: "sdk"
			}
			output: {
				directory: "./context"
			}
		}
  }

  macos: scullery.#Cake & {
		recipe: {
			input: {
				dockerfile: "Dockerfile.macos"
			}
			output: {
				images: {
					names: [...string] | * ["tools"],
					tags: [...string] | * ["macos-latest"]
				}
			}
			metadata: {
				title: "Dubo Tools for macOS",
				description: "Some tools collection: cue, dagger, buildctl, goello, etc",
			}
		}
  }
}

UserDefined: scullery.#Icing

cakes: {
	macos: icing: UserDefined
	linux: icing: UserDefined
	linux_dev: icing: UserDefined
	sdk: icing: UserDefined
}

// Injectors
injectors: {
	suite: =~ "^(?:jessie|stretch|buster|bullseye|sid)$" @tag(suite, type=string)
	date: =~ "^[0-9]{4}-[0-9]{2}-[0-9]{2}$" @tag(date, type=string)
	platforms: string @tag(platforms, type=string)
	registry: string @tag(registry, type=string)
}

cakes: sdk: recipe: {
	input: from: registry: injectors.registry
}

cakes: macos: recipe: {
	input: from: registry: injectors.registry

	output: images: tags: ["macos-" + injectors.suite + "-" + injectors.date, "macos-" + injectors.suite + "-latest", "macos-latest"]
	metadata: ref_name: "macos-" + injectors.suite + "-" + injectors.date
}

cakes: linux: recipe: {
	input: from: registry: injectors.registry

	if injectors.platforms != _|_ {
		process: platforms: strings.Split(injectors.platforms, ",")
	}

	output: images: tags: ["linux-" + injectors.suite + "-" + injectors.date, "linux-" + injectors.suite + "-latest", "linux-latest"]
	metadata: ref_name: "linux-" + injectors.suite + "-" + injectors.date
}

cakes: linux_dev: recipe: {
	input: from: registry: injectors.registry

	if injectors.platforms != _|_ {
		process: platforms: strings.Split(injectors.platforms, ",")
	}

	output: images: tags: ["linux-dev-" + injectors.suite + "-" + injectors.date, "linux-dev-" + injectors.suite + "-latest", "linux-dev-latest"]
	metadata: ref_name: "linux-dev-" + injectors.suite + "-" + injectors.date
}

