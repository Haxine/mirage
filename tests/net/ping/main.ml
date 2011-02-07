open Lwt 
open Printf
open Net

let ip = match Nettypes.ipv4_addr_of_string "10.0.0.2" with Some x -> x |None -> assert false
let nm = match Nettypes.ipv4_addr_of_string "255.255.255.0" with Some x -> x |None -> assert false

let main () =
  lwt vifs = OS.Ethif.enumerate () in
  let arp_t = List.map (fun id ->
    lwt (t,thread) = Ipv4.create id in
    Ipv4.set_ip t ip >>
    Ipv4.set_netmask t nm >>
    let _ = Icmp.create t in 
    thread
  ) vifs in
  join arp_t >>
  return (printf "success\n%!")

let _ = OS.Main.run (main ())
