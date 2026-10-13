use greet.nu

def main [name: string] {
  print (greet $name)
  print (^@true@ | complete | get exit_code)
}
