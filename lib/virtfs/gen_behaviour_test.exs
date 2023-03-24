defmodule Virtfs.GenBehaviourTest do
  use ExUnit.Case
  use Mneme, action: :accept
  alias Virtfs.GenBehaviour

  describe "gen" do
    test "works" do
      auto_assert(
        [
          {:write!, 3, [:fs, :path, :content]},
          {:write, 3, [:fs, :path, :content]},
          {:rm_rf!, 2, [:fs, :path]},
          {:rm_rf, 2, [:fs, :path]},
          {:rm!, 2, [:fs, :path]},
          {:rm, 2, [:fs, :path]},
          {:rename!, 3, [:fs, :src, :dest]},
          {:rename, 3, [:fs, :src, :dest]},
          {:read!, 2, [:fs, :path]},
          {:read, 2, [:fs, :path]},
          {:mkdir_p!, 2, [:fs, :path]},
          {:mkdir_p, 2, [:fs, :path]},
          {:exists?, 2, [:fs, :path]},
          {:dir?, 2, [:fs, :path]},
          {:copy!, 3, [:fs, :src, :dest]},
          {:copy, 3, [:fs, :src, :dest]},
          {:cd!, 2, [:fs, :path]},
          {:cd, 2, [:fs, :path]}
        ] <- GenBehaviour.gen(Virtfs.Behaviour)
      )
    end
  end
end
