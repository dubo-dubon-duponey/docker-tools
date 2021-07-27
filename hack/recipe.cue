package cake

import (
	"duponey.cloud/scullery"
	"duponey.cloud/buildkit/types"
	"strings"
)

// XXX WIP: clearly the injector is defective at this point and has to be rethought
// It's probably a better approach to hook it into the recipe, or the env to avoid massive re-use problems

// Entry point if there are environmental definitions
UserDefined: scullery.#Icing & {
	// XXX add injectors here?
//				cache: injector._cache_to
//				cache: injector._cache_from
}

defaults: {
	tags: [
		types.#Image & {
			registry: "push-registry.local"
 			image: "dubo-dubon-duponey/tools"
			// tag: cakes.debian.recipe.process.args.TARGET_SUITE + "-" + cakes.debian.recipe.process.args.TARGET_DATE
		},
		types.#Image & {
			registry: "push-registry.local"
			image: "dubo-dubon-duponey/tools"
			tag: "latest"
		},
		types.#Image & {
   		registry: "ghcr.io"
   		image: "dubo-dubon-duponey/tools"
   		// tag: cakes.debian.recipe.process.args.TARGET_SUITE + "-" + cakes.debian.recipe.process.args.TARGET_DATE
   	},
		types.#Image & {
			registry: "ghcr.io"
			image: "dubo-dubon-duponey/tools"
			tag: "latest"
		}
	],
	platforms: [
		types.#Platforms.#ARM64,
		types.#Platforms.#AMD64,
		types.#Platforms.#I386,
		types.#Platforms.#V7,
		types.#Platforms.#V6,
		types.#Platforms.#S390X,
		types.#Platforms.#PPC64LE,
	]

	suite: "bullseye"
	date: "2021-07-01"
}

injector: {
	_i_tags: * strings.Join([for _v in defaults.tags {_v.toString}], ",") | string @tag(tags, type=string)

	_tags: [for _k, _v in strings.Split(_i_tags, ",") {
		types.#Image & {#fromString: _v}
	}]
	// _tags: [...types.#Image]
	//if _i_tags != "" {
	//}
	//_tags: [for _k, _v in strings.Split(_i_tags, ",") {
	//	types.#Image & {#fromString: _v}
	//}]

	_i_platforms: * strings.Join(defaults.platforms, ",") | string @tag(platforms, type=string)

	_platforms: [...string]

	if _i_platforms == "" {
		_platforms: []
	}
	if _i_platforms != "" {
		_platforms: [for _k, _v in strings.Split(_i_platforms, ",") {_v}]
	}

	_target_suite: * defaults.suite | =~ "^(?:buster|bullseye|sid)$" @tag(target_suite, type=string)
	_target_date: * defaults.date | =~ "^[0-9]{4}-[0-9]{2}-[0-9]{2}$" @tag(target_date, type=string)
}

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
				from: runtime: types.#Image & {#fromString: *"ghcr.io/dubo-dubon-duponey/debian:bullseye-2021-07-01" | string @tag(from_image, type=string)}
				from: builder: types.#Image & {#fromString: "ghcr.io/dubo-dubon-duponey/base:builder-bullseye-2021-07-01@sha256:dbe45d04091f027b371e1bd4ea994f095a8b2ebbdd89357c56638fb678218151"}
				from: auditor: types.#Image & {#fromString: "ghcr.io/dubo-dubon-duponey/base:auditor-bullseye-2021-07-01"}
				from: tools: types.#Image & {#fromString: "ghcr.io/dubo-dubon-duponey/tools:linux-bullseye-2021-07-01"}
			}
			process: {
				platforms: injector._platforms
			}
			output: {
				tags: injector._tags
			}
			metadata: {
				// ref_name: process.args.TARGET_SUITE + "-" + process.args.TARGET_DATE,
				title: "Dubo Tools for Linux",
				description: "Some tools collection: cue, dagger, buildctl, goello, etc",
			}
		}
		icing: UserDefined
  }

	// This one processes a local SDK, typically on a mac (or somewhere the SDK is present), targets only the current platform
	// and export a tarball locally without pushing anything
	// Making it push the SDK would probably violate Apple terms of redistribution, so...

  sdk: scullery.#Cake & {
		recipe: {
			input: {
				dockerfile: "Dockerfile.macos"
				from: runtime: types.#Image & {#fromString: *"ghcr.io/dubo-dubon-duponey/debian:bullseye-2021-07-01" | string @tag(from_image, type=string)}
				from: builder: types.#Image & {#fromString: "ghcr.io/dubo-dubon-duponey/base:builder-bullseye-2021-07-01@sha256:dbe45d04091f027b371e1bd4ea994f095a8b2ebbdd89357c56638fb678218151"}
				from: auditor: types.#Image & {#fromString: "ghcr.io/dubo-dubon-duponey/base:auditor-bullseye-2021-07-01"}
				from: tools: types.#Image & {#fromString: "ghcr.io/dubo-dubon-duponey/tools:linux-bullseye-2021-07-01"}
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
			metadata: {
				// ref_name: process.args.TARGET_SUITE + "-" + process.args.TARGET_DATE,
				// title: "Dubo Tools",
				// description: "Usefull tools",
			}
		}
		icing: UserDefined
  }

  macos: scullery.#Cake & {
		recipe: {
			input: {
				dockerfile: "Dockerfile.macos"
				from: runtime: types.#Image & {#fromString: *"ghcr.io/dubo-dubon-duponey/debian:bullseye-2021-07-01" | string @tag(from_image, type=string)}
				from: builder: types.#Image & {#fromString: "ghcr.io/dubo-dubon-duponey/base:builder-bullseye-2021-07-01@sha256:dbe45d04091f027b371e1bd4ea994f095a8b2ebbdd89357c56638fb678218151"}
				from: auditor: types.#Image & {#fromString: "ghcr.io/dubo-dubon-duponey/base:auditor-bullseye-2021-07-01"}
				from: tools: types.#Image & {#fromString: "ghcr.io/dubo-dubon-duponey/tools:linux-bullseye-2021-07-01"}
			}
			process: {
				// target: "foo"
				// target: "builder"
				// platforms:
			}
			output: {
				tags: injector._tags
			}
			metadata: {
				// XXX ref_name is a problem
				// ref_name: process.args.TARGET_SUITE + "-" + process.args.TARGET_DATE,
				title: "Dubo Tools for macOS",
				description: "Some tools collection: cue, dagger, buildctl, goello, etc",
			}
		}
		icing: UserDefined
  }
}
