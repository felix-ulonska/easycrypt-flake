(* -------------------------------------------------------------------- *)
open EcUtils
open EcIdent
open EcMemory
open EcModules
open EcTypes
open EcFol
open EcBaseLogic
open EcLogic
open EcPV

(* -------------------------------------------------------------------- *)
type 'a sdestr_t  = string -> stmt -> 'a * stmt
type 'a sdestr2_t = string -> stmt -> stmt -> 'a * 'a * stmt * stmt

(* -------------------------------------------------------------------- *)
let s_first proj error s =
  match s.s_node with
  | [] -> error ()
  | i :: r -> try (proj i, stmt r) with Not_found -> error ()

let s_first2 proj error sl sr =
  let hl,tl = s_first proj error sl in
  let hr,tr = s_first proj error sr in
    (hl, hr, tl, tr)

let first_error si st () = 
  cannot_apply st (Printf.sprintf "invalid first instruction: expected [%s]" si)

let s_first_asgn    st = s_first  destr_asgn   (first_error "asgn"   st)
let s_first_asgns   st = s_first2 destr_asgn   (first_error "asgn"   st)
let s_first_rnd     st = s_first  destr_rnd    (first_error "rnd"    st)
let s_first_rnds    st = s_first2 destr_rnd    (first_error "rnd"    st)
let s_first_call    st = s_first  destr_call   (first_error "call"   st)
let s_first_calls   st = s_first2 destr_call   (first_error "call"   st)
let s_first_if      st = s_first  destr_if     (first_error "if"     st)
let s_first_ifs     st = s_first2 destr_if     (first_error "if"     st)
let s_first_while   st = s_first  destr_while  (first_error "while"  st)
let s_first_whiles  st = s_first2 destr_while  (first_error "while"  st)
let s_first_assert  st = s_first  destr_assert (first_error "assert" st)
let s_first_asserts st = s_first2 destr_assert (first_error "assert" st)

(* -------------------------------------------------------------------- *)
let s_last proj error s =
  match List.rev s.s_node with
  | [] -> error ()
  | i :: r -> try (proj i, rstmt r) with Not_found -> error ()

let s_last2 destr_i error sl sr =
  let hl,tl = s_last destr_i error sl in
  let hr,tr = s_last destr_i error sr in
    (hl, hr, tl, tr)

let last_error si st () = 
  cannot_apply st (Printf.sprintf "invalid last instruction: expected [%s]" si)

let s_last_asgn    st = s_last  destr_asgn   (last_error "asgn"   st)
let s_last_asgns   st = s_last2 destr_asgn   (last_error "asgn"   st)
let s_last_rnd     st = s_last  destr_rnd    (last_error "rnd"    st)
let s_last_rnds    st = s_last2 destr_rnd    (last_error "rnd"    st)
let s_last_call    st = s_last  destr_call   (last_error "call"   st)
let s_last_calls   st = s_last2 destr_call   (last_error "call"   st)
let s_last_if      st = s_last  destr_if     (last_error "if"     st)
let s_last_ifs     st = s_last2 destr_if     (last_error "if"     st)
let s_last_while   st = s_last  destr_while  (last_error "while"  st)
let s_last_whiles  st = s_last2 destr_while  (last_error "while"  st)
let s_last_assert  st = s_last  destr_assert (last_error "assert" st)
let s_last_asserts st = s_last2 destr_assert (last_error "assert" st)

(* -------------------------------------------------------------------- *)
let t_as_hoareF c =
  try destr_hoareF c with DestrError _ -> tacerror (NotPhl (Some true))
let t_as_hoareS c =
  try destr_hoareS c with DestrError _ -> tacerror (NotPhl (Some true))
let t_as_bdHoareF c =
  try destr_bdHoareF c with DestrError _ -> tacerror (NotPhl (Some true))
let t_as_bdHoareS c =
  try destr_bdHoareS c with DestrError _ -> tacerror (NotPhl (Some true))
let t_as_equivF c =
  try destr_equivF c with DestrError _ -> tacerror (NotPhl (Some false))
let t_as_equivS c =
  try destr_equivS c with DestrError _ -> tacerror (NotPhl (Some false))

(* -------------------------------------------------------------------- *)
let get_pre f = 
  match f.f_node with
  | FhoareF hf   -> hf.hf_pr
  | FhoareS hs   -> hs.hs_pr
  | FbdHoareF hf -> hf.bhf_pr
  | FbdHoareS hs -> hs.bhs_pr
  | FequivF ef   -> ef.ef_pr
  | FequivS es   -> es.es_pr
  | _            -> tacerror (NotPhl None)

let get_post f = 
  match f.f_node with
  | FhoareF hf   -> hf.hf_po
  | FhoareS hs   -> hs.hs_po
  | FbdHoareF hf -> hf.bhf_po
  | FbdHoareS hs -> hs.bhs_po
  | FequivF ef   -> ef.ef_po
  | FequivS es   -> es.es_po
  | _            -> tacerror (NotPhl None)

let set_pre ~pre f = 
  match f.f_node with
 | FhoareF hf   -> f_hoareF pre hf.hf_f hf.hf_po
 | FhoareS hs   -> f_hoareS_r { hs with hs_pr = pre} 
 | FbdHoareF hf -> f_bdHoareF pre hf.bhf_f hf.bhf_po hf.bhf_cmp hf.bhf_bd
 | FbdHoareS hs -> f_bdHoareS_r { hs with bhs_pr = pre}
 | FequivF ef   -> f_equivF pre ef.ef_fl ef.ef_fr ef.ef_po
 | FequivS es   -> f_equivS_r { es with es_pr = pre }
 | _            -> tacerror (NotPhl None)

(* -------------------------------------------------------------------- *)
let t_hS_or_bhS_or_eS ?th ?tbh ?te g =
  match (get_concl g).f_node with
  | FhoareS   _ when th  <> None -> (oget th ) g
  | FbdHoareS _ when tbh <> None -> (oget tbh) g
  | FequivS   _ when te  <> None -> (oget te ) g
    
  | _ -> tacerror (NotPhl None)

(* -------------------------------------------------------------------- *)
let s_split_i msg i s = 
  let len = List.length s.s_node in
    if not (0 < i && i <= len) then
      tacerror (InvalidCodePosition (msg, i, 1, len));
    let (hd, tl) = EcModules.s_split (i-1) s in
      (hd, List.hd tl, (List.tl tl))

let s_split msg i s =
  let len = List.length s.s_node in
    if i < 0 || len < i then
      tacerror (InvalidCodePosition (msg, i, 0, len));
    EcModules.s_split i s

let s_split_o msg i s = 
  match i with
  | None   -> ([], s.s_node)
  | Some i -> s_split msg i s 

(* -------------------------------------------------------------------- *)
let tag_sym_with_side name m =
  if      EcIdent.id_equal m EcFol.mleft  then (name ^ "_L")
  else if EcIdent.id_equal m EcFol.mright then (name ^ "_R")
  else    name

let id_of_pv pv m =
  let id = EcPath.basename pv.pv_name.EcPath.x_sub in
  let id = tag_sym_with_side id m in
    EcIdent.create id

let id_of_mp mp m = 
  let name = 
    match mp.EcPath.m_top with
    | `Local id -> EcIdent.name id 
    | _ -> assert false
  in
    EcIdent.create (tag_sym_with_side name m)

(* -------------------------------------------------------------------- *)
type lv_subst_t = (lpattern * form) * (prog_var * memory * form) list

let lv_subst m lv f : lv_subst_t =
  match lv with
  | LvVar(pv,t) ->
    let id = id_of_pv pv m in 
    (LSymbol (id,t), f), [pv,m,f_local id t]

  | LvTuple vs ->
    let ids = List.map (fun (pv,t) -> id_of_pv pv m, t) vs in
    let s = List.map2 (fun (pv,_) (id,t) -> pv,m,f_local id t) vs ids in
    (LTuple ids, f), s

  | LvMap((p,tys),pv,e,ty) ->
    let id = id_of_pv pv m in 
    let set = f_op p tys (toarrow [ty; e.e_ty; f.f_ty] ty) in
    let f = f_app set [f_pvar pv ty m; form_of_expr m e; f] ty in
    (LSymbol (id,ty), f), [pv,m,f_local id ty]

let mk_let_of_lv_substs env (lets, f) = 
  let rec aux s lets =
    match lets with
    | [] -> PVM.subst env s f 
    | ((lp,f1), toadd) :: lets ->
      let f1 = PVM.subst env s f1 in
      let s = 
        List.fold_left (fun s (pv,m,fp) -> PVM.add env pv m fp s) s toadd in
      f_let_simpl lp f1 (aux s lets) in
  if lets = [] then f else aux PVM.empty lets 

let subst_form_lv env m lv t f =
  let lets = lv_subst m lv t in
    mk_let_of_lv_substs env ([lets],f)

(* -------------------------------------------------------------------- *)
(* Remark: m is only used to create fresh name, id_of_pv *)
let generalize_subst env m uelts uglob = 
  let create (pv, ty) = id_of_pv pv m, GTty ty in
  let b = List.map create uelts in
  let s =
    List.fold_left2
      (fun s (pv, ty) (id, _) ->
        Mpv.add env pv (f_local id ty) s)
      Mpv.empty uelts b
  in
  let create mp = id_of_mp mp m, GTty (tglob mp) in
  let b' = List.map create uglob in
  let s  =
    List.fold_left2
      (fun s mp (id, _) ->
        Mpv.add_glob env mp (f_local id (tglob mp)) s)
      s uglob b'
  in
    (b' @ b, s)

let generalize_mod env m modi f =
  let (elts, glob) = PV.elements modi in

  (* 1. Compute the prog-vars and the globals used in [f] *)
  let fv = PV.fv env m f in

  (* 2. Split [modi] into two parts:
   *     the one used in the free-vars and the others *)
  let (uelts, nelts) = List.partition (fun (pv, _) -> PV.mem_pv env pv fv) elts in
  let (uglob, nglob) = List.partition (fun mp -> PV.mem_glob env mp fv) glob in

  (* 3. We build the related substitution *)

  (* 3.a. Add the global variables *)
  let (bd, s) = generalize_subst env m uelts uglob in

  (* 3.b. Check that the substituion don't clash with some
          other unmodified variables *)
  List.iter (fun (pv,_) -> Mpv.check_npv env pv s) nelts;
  List.iter (fun mp -> Mpv.check_glob env mp s) nglob;

  (* 3.c. Perform the substitution *)
  let s = PVM.of_mpv s m in
  let f = PVM.subst env s f in
    f_forall_simpl bd f
