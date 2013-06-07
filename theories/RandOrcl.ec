require import Int.
require import Map.

type from.
type to.

op dsample: to distr. (* Distribution to use on the target type *)
op qO: int.           (* Maximum number of calls by the adversary *)
op default: to.       (* Default element to return on error by the adversary wrapper *)

(* Signature for random oracles from "from" to "to" *)
module type Oracle = {
  fun init(): unit
  fun o(x:from): to
}.

theory ROM.
  (* Bare random oracle for use in schemes *)
  module RO: Oracle = {
    var m:(from,to) map

    fun init(): unit = {
      m = empty;
    }
  
    fun o(x:from): to = {
      var y : to;
      y = $dsample;
      if (!in_dom x m) m.[x] = y;
      return proj (m.[x]);
    }
  }.

  (* Wrapped random oracle for use by the adversary *)
  module ARO(RO:Oracle) : Oracle = {
    var log: from Set.set

    fun o(x:from): to = {
      var y: to = default;
      if (Set.mem x log || Set.card log < qO) {
        log = Set.add x log;
        y := RO.o(x); 
      }
      return y;
    }

    fun init(): unit = {
      log = Set.empty;
      RO.init(); 
    }
  }.
end ROM.
