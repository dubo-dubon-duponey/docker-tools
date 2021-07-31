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
				platforms: types.#Platforms | * [
					types.#Platforms.#AMD64,
					types.#Platforms.#ARM64,
					types.#Platforms.#I386,
					types.#Platforms.#V7,
					types.#Platforms.#V6,
					types.#Platforms.#S390X,
					types.#Platforms.#PPC64LE,
				]
			}
			output: {
				images: {
					registries: {...} | * {
						"ghcr.io": "dubo-dubon-duponey",
					},
					names: [...string] | * ["tools"],
					tags: [...string] | * ["linux-latest"]
				}
			}
			metadata: {
				title: "Dubo Tools for Linux",
				description: "Some tools collection: cue, dagger, buildctl, goello, etc",
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
					registries: {...} | * {
						"ghcr.io": "dubo-dubon-duponey",
					},
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

	output: images: registries: {
		"push-registry.local": "dubo-dubon-duponey",
		"ghcr.io": "dubo-dubon-duponey",
		"docker.io": "dubodubonduponey"
	}

	output: images: tags: ["linux-" + injectors.suite + "-" + injectors.date, "linux-" + injectors.suite + "-latest", "linux-latest"]
	metadata: ref_name: "linux-" + injectors.suite + "-" + injectors.date
}

cakes: linux: recipe: {
	input: from: registry: injectors.registry

	if injectors.platforms != _|_ {
		process: platforms: strings.Split(injectors.platforms, ",")
	}

	output: images: registries: {
		"push-registry.local": "dubo-dubon-duponey",
		"ghcr.io": "dubo-dubon-duponey",
		"docker.io": "dubodubonduponey"
	}

	output: images: tags: ["linux-" + injectors.suite + "-" + injectors.date, "linux-" + injectors.suite + "-latest", "linux-latest"]
	metadata: ref_name: "linux-" + injectors.suite + "-" + injectors.date
}

