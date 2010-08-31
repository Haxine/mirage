(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Lwt
open Mlnet_types
open Printf

module MS=Mpl.Mpl_stdlib

module ICMP(IP:Ipv4.UP) = struct
 
  type t = {
    ip: IP.t;
  }

  let input t ip = function
  |`EchoRequest icmp ->
    (* Create the ICMP echo reply *)
    let dest_ip = ipv4_addr_of_uint32 ip#src in
    let sequence = icmp#sequence in
    let identifier = icmp#identifier in
    let data = `Frag icmp#data_frag in
    let icmpfn env =
      let packet = Mpl.Icmp.EchoReply.t ~identifier ~sequence ~data env in
      let csum = Checksum.icmp_checksum (MS.env_pos env 0) in
      packet#set_checksum csum;
    in
    (* Create the IPv4 packet *)
    let id = ip#id in 
    let src = ip#dest in
    let dest = ip#src in
    let ipfn = Mpl.Ipv4.t ~id ~ttl:34 ~protocol:`ICMP ~src
        ~dest ~options:`None ~data:(`Sub icmpfn) in
    IP.output t.ip ~dest_ip ipfn

  |_ -> print_endline "dropped icmp"; return ()

  let create ip =
    let t = { ip } in
    IP.attach ip (`ICMP (input t));
    { ip }

end