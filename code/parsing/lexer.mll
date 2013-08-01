{
open Lexing
open Parser

exception SyntaxError of string

let next_line lexbuf =
  let pos = lexbuf.lex_curr_p in
  lexbuf.lex_curr_p <-
    { pos with pos_bol = lexbuf.lex_curr_pos;
               pos_lnum = pos.pos_lnum + 1
    }

let add_utf8 buf code =
  if code <= 0x7f then
    Buffer.add_char buf (Char.chr code)
  else if code <= 0x7ff then begin
    Buffer.add_char buf (Char.chr (0b11000000 lor ((code lsr 6) land 0x3f)));
    Buffer.add_char buf (Char.chr (0b10000000 lor (code land 0x3f)))
  end else begin
    Buffer.add_char buf (Char.chr (0b11100000 lor ((code lsr 12) land 0x3f)));
    Buffer.add_char buf (Char.chr (0b10000000 lor ((code lsr 6) land 0x3f)));
    Buffer.add_char buf (Char.chr (0b10000000 lor (code land 0x3f)))
  end
}

(* part 1 *)
let int = '-'? ['1'-'9'] ['0'-'9']*

(* part 2 *)
let digits = ['0'-'9']+
let frac = '.' digits
let exp = ['e' 'E'] ['-' '+']? digits
let float = int (frac | exp | frac exp)

(* part 3 *)
let white = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"

let id = ['a'-'z' 'A'-'Z' '_'] ['a'-'z' 'A'-'Z' '0'-'9' '_']*
let hex = ['0'-'9' 'a'-'f' 'A'-'F']

(* part 4 *)
rule read = parse
| white { read lexbuf }
| newline { next_line lexbuf; read lexbuf }
| int { INT (int_of_string (Lexing.lexeme lexbuf)) }
| float { FLOAT (float_of_string (Lexing.lexeme lexbuf)) }
| "true" { TRUE }
| "false" { FALSE }
| "null" { NULL }
| id { ID (Lexing.lexeme lexbuf) }
| '"' { read_string (Buffer.create 17) lexbuf }
| '{' { LEFT_BRACE }
| '}' { RIGHT_BRACE }
| '[' { LEFT_BRACK }
| ']' { RIGHT_BRACK }
| ':' { COLON }
| ',' { COMMA }
| _ { raise (SyntaxError ("Unexpected character: " ^ Lexing.lexeme lexbuf)) }
| eof { EOF }

(* part 5 *)
and read_string buf = parse
| '"' { STRING (Buffer.contents buf) }
| '\\' '/' { Buffer.add_char buf '/'; read_string buf lexbuf }
| '\\' '\\' { Buffer.add_char buf '\\'; read_string buf lexbuf }
| '\\' 'b' { Buffer.add_char buf '\b'; read_string buf lexbuf }
| '\\' 'f' { Buffer.add_char buf '\012'; read_string buf lexbuf }
| '\\' 'n' { Buffer.add_char buf '\n'; read_string buf lexbuf }
| '\\' 'r' { Buffer.add_char buf '\r'; read_string buf lexbuf }
| '\\' 't' { Buffer.add_char buf '\t'; read_string buf lexbuf }
| '\\' 'u' hex hex hex hex
  { let string_code = String.sub (Lexing.lexeme lexbuf) 2 4 in
    let code = int_of_string ("0x" ^ string_code) in
    add_utf8 buf code;
    read_string buf lexbuf
  }
| [^ '"' '\\']+
  { Buffer.add_string buf (Lexing.lexeme lexbuf);
    read_string buf lexbuf
  }
| _ { raise (SyntaxError ("Illegal string character: " ^ Lexing.lexeme lexbuf)) }
| eof { raise (SyntaxError ("String is not terminated")) }