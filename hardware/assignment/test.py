import sys

def point_doubling(p, X1, Y1, Z1, a, b3):
  return point_addition(p, X1, Y1, Z1, X1, Y1, Z1, a, b3)

def point_addition(p, X1, Y1, Z1, X2, Y2, Z2, a, b3):
  #sys.stdout.write(f" 1. t0 = X1 * X2 = {X1:08b} * {X2:08b}")
  t0 = (X1 * X2) % p
  #sys.stdout.write(f" = {t0:08b}\n")
  #sys.stdout.write(f" 2. t1 = Y1 * Y2 = {Y1:08b} * {Y2:08b}")
  t1 = (Y1 * Y2) % p
  #sys.stdout.write(f" = {t1:08b}\n")
  #sys.stdout.write(f" 3. t2 = Z1 * Z2 = {Z1:08b} * {Z2:08b}")
  t2 = (Z1 * Z2) % p
  #sys.stdout.write(f" = {t2:08b}\n")
  #sys.stdout.write(f" 4. t3 = X1 + Y1 = {X1:08b} + {Y1:08b}")
  t3 = (X1 + Y1) % p
  #sys.stdout.write(f" = {t3:08b}\n")
  #sys.stdout.write(f" 5. t4 = X2 + Y2 = {X2:08b} + {Y2:08b}")
  t4 = (X2 + Y2) % p
  #sys.stdout.write(f" = {t4:08b}\n")
  #sys.stdout.write(f" 6. t3 = t3 * t4 = {t3:08b} * {t4:08b}")
  t3 = (t3 * t4) % p
  #sys.stdout.write(f" = {t3:08b}\n")
  #sys.stdout.write(f" 7. t4 = t0 + t1 = {t0:08b} + {t1:08b}")
  t4 = (t0 + t1) % p
  #sys.stdout.write(f" = {t4:08b}\n")
  #sys.stdout.write(f" 8. t3 = t3 - t4 = {t3:08b} - {t4:08b}")
  t3 = (t3 - t4) % p
  #sys.stdout.write(f" = {t3:08b}\n")
  #sys.stdout.write(f" 9. t4 = X1 + Z1 = {X1:08b} + {Z1:08b}")
  t4 = (X1 + Z1) % p
  #sys.stdout.write(f" = {t4:08b}\n")
  #sys.stdout.write(f"10. t5 = X2 + Z2 = {X2:08b} + {Z2:08b}")
  t5 = (X2 + Z2) % p
  #sys.stdout.write(f" = {t5:08b}\n")
  #sys.stdout.write(f"11. t4 = t4 * t5 = {t4:08b} * {t5:08b}")
  t4 = (t4 * t5) % p
  #sys.stdout.write(f" = {t4:08b}\n")
  #sys.stdout.write(f"12. t5 = t0 + t2 = {t0:08b} + {t2:08b}")
  t5 = (t0 + t2) % p
  #sys.stdout.write(f" = {t5:08b}\n")
  #sys.stdout.write(f"13. t4 = t4 - t5 = {t4:08b} - {t5:08b}")
  t4 = (t4 - t5) % p
  #sys.stdout.write(f" = {t4:08b}\n")
  #sys.stdout.write(f"14. t5 = Y1 + Z1 = {Y1:08b} + {Z1:08b}")
  t5 = (Y1 + Z1) % p
  #sys.stdout.write(f" = {t5:08b}\n")
  #sys.stdout.write(f"15. X3 = Y2 + Z2 = {Y2:08b} + {Z2:08b}")
  X3 = (Y2 + Z2) % p
  #sys.stdout.write(f" = {X3:08b}\n")
  #sys.stdout.write(f"16. t5 = t5 * X3 = {t5:08b} * {X3:08b}")
  t5 = (t5 * X3) % p
  #sys.stdout.write(f" = {t5:08b}\n")
  #sys.stdout.write(f"17. X3 = t1 + t2 = {t1:08b} + {t2:08b}")
  X3 = (t1 + t2) % p
  #sys.stdout.write(f" = {X3:08b}\n")
  #sys.stdout.write(f"18. t5 = t5 - X3 = {t5:08b} - {X3:08b}")
  t5 = (t5 - X3) % p
  #sys.stdout.write(f" = {t5:08b}\n")
  #sys.stdout.write(f"19. Z3 =  a * t4 = {a:08b} * {t4:08b}")
  Z3 = (a * t4) % p
  #sys.stdout.write(f" = {Z3:08b}\n")
  #sys.stdout.write(f"20. X3 = b3 * t2 = {b3:08b} * {t2:08b}")
  X3 = (b3 * t2) % p
  #sys.stdout.write(f" = {X3:08b}\n")
  #sys.stdout.write(f"21. Z3 = X3 + Z3 = {X3:08b} + {Z3:08b}")
  Z3 = (X3 + Z3) % p
  #sys.stdout.write(f" = {Z3:08b}\n")
  #sys.stdout.write(f"22. X3 = t1 - Z3 = {t1:08b} - {Z3:08b}")
  X3 = (t1 - Z3) % p
  #sys.stdout.write(f" = {X3:08b}\n")
  #sys.stdout.write(f"23. Z3 = t1 + Z3 = {t1:08b} + {Z3:08b}")
  Z3 = (t1 + Z3) % p
  #sys.stdout.write(f" = {Z3:08b}\n")
  #sys.stdout.write(f"24. Y3 = X3 * Z3 = {X3:08b} * {Z3:08b}")
  Y3 = (X3 * Z3) % p
  #sys.stdout.write(f" = {Y3:08b}\n")
  #sys.stdout.write(f"25. t1 = t0 + t0 = {t0:08b} + {t0:08b}")
  t1 = (t0 + t0) % p
  #sys.stdout.write(f" = {t1:08b}\n")
  #sys.stdout.write(f"26. t1 = t1 + t0 = {t1:08b} + {t0:08b}")
  t1 = (t1 + t0) % p
  #sys.stdout.write(f" = {t1:08b}\n")
  #sys.stdout.write(f"27. t2 =  a * t2 = {a:08b} * {t2:08b}")
  t2 = (a * t2) % p
  #sys.stdout.write(f" = {t2:08b}\n")
  #sys.stdout.write(f"28. t4 = b3 * t4 = {b3:08b} * {t4:08b}")
  t4 = (b3 * t4) % p
  #sys.stdout.write(f" = {t4:08b}\n")
  #sys.stdout.write(f"29. t1 = t1 + t2 = {t1:08b} + {t2:08b}")
  t1 = (t1 + t2) % p
  #sys.stdout.write(f" = {t1:08b}\n")
  #sys.stdout.write(f"30. t2 = t0 - t2 = {t0:08b} - {t2:08b}")
  t2 = (t0 - t2) % p
  #sys.stdout.write(f" = {t2:08b}\n")
  #sys.stdout.write(f"31. t2 =  a * t2 = {a:08b} * {t2:08b}")
  t2 = (a * t2) % p
  #sys.stdout.write(f" = {t2:08b}\n")
  #sys.stdout.write(f"32. t4 = t4 + t2 = {t4:08b} + {t2:08b}")
  t4 = (t4 + t2) % p
  #sys.stdout.write(f" = {t4:08b}\n")
  #sys.stdout.write(f"33. t0 = t1 * t4 = {t1:08b} * {t4:08b}")
  t0 = (t1 * t4) % p
  #sys.stdout.write(f" = {t0:08b}\n")
  #sys.stdout.write(f"34. Y3 = Y3 + t0 = {Y3:08b} + {t0:08b}")
  Y3 = (Y3 + t0) % p
  #sys.stdout.write(f" = {Y3:08b}\n")
  #sys.stdout.write(f"35. t0 = t5 * t4 = {t5:08b} * {t4:08b}")
  t0 = (t5 * t4) % p
  #sys.stdout.write(f" = {t0:08b}\n")
  #sys.stdout.write(f"36. X3 = t3 * X3 = {t3:08b} * {X3:08b}")
  X3 = (t3 * X3) % p
  #sys.stdout.write(f" = {X3:08b}\n")
  #sys.stdout.write(f"37. X3 = X3 - t0 = {X3:08b} - {t0:08b}")
  X3 = (X3 - t0) % p
  #sys.stdout.write(f" = {X3:08b}\n")
  #sys.stdout.write(f"38. t0 = t3 * t1 = {t3:08b} * {t1:08b}")
  t0 = (t3 * t1) % p
  #sys.stdout.write(f" = {t0:08b}\n")
  #sys.stdout.write(f"39. Z3 = t5 * Z3 = {t5:08b} * {Z3:08b}")
  Z3 = (t5 * Z3) % p
  #sys.stdout.write(f" = {Z3:08b}\n")
  #sys.stdout.write(f"40. Z3 = Z3 + t0 = {Z3:08b} + {t0:08b}")
  Z3 = (Z3 + t0) % p
  #sys.stdout.write(f" = {Z3:08b}\n")
  # print(f"X3: {X3:08b}")
  # print(f"Y3: {Y3:08b}")
  # print(f"Z3: {Z3:08b}")

  return (X3, Y3, Z3)


def scalar_mult(p, X1, Y1, Z1, s, a, b3):
  n = 8
  i = n - 1
  r0_x = 0
  r0_y = 1
  r0_z = 0
  r1_x = X1
  r1_y = Y1
  r1_z = Z1

  for i in range(n-1, -1, -1):
    if s & (1 << i) > 0:
      (x,y,z) = point_addition(p, r0_x, r0_y, r0_z, r1_x, r1_y, r1_z, a, b3)
      print(f"point add bit 1 {i} X1: {x:08b}, Y1: {y:08b}, Z1: {z:08b}")
      r0_x = x
      r0_y = y
      r0_z = z
      (x,y,z) = point_doubling(p, r1_x, r1_y, r1_z, a, b3)
      print(f"point doubling bit 1 {i} X2: {x:08b}, Y2: {y:08b}, Z2: {z:08b}")
      r1_x = x
      r1_y = y
      r1_z = z
    else:
      (x,y,z) = point_addition(p, r0_x, r0_y, r0_z, r1_x, r1_y, r1_z, a, b3)
      print(f"point add bit 0 {i} X2: {x:08b}, Y2: {y:08b}, Z2: {z:08b}")
      r1_x = x
      r1_y = y
      r1_z = z
      (x,y,z) = point_doubling(p, r0_x, r0_y, r0_z, a, b3)
      print(f"point doubling bit 0 {i} X1: {x:08b}, Y1: {y:08b}, Z1: {z:08b}")
      r0_x = x
      r0_y = y
      r0_z = z
  
  return (r0_x, r0_y, r0_z)


if __name__ == "__main__":
  p = 0xffffffff00000001000000000000000000000000ffffffffffffffffffffffff
  a = 0xffffffff00000001000000000000000000000000fffffffffffffffffffffffc
  b = 0x5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b
  b3 = 3 * b
  x = 0x771237aee432c1de1760a14d5ef2dc2bed90151a4512254b3a8166b46d8d03d3
  y = 0x24a827e6110102663b61e20b703294289f517c602bcfbdb28eba3d358ef04207
  z = 0x67e35ea00df06783de49f09bb1d0bfc6d32246304390fa40f9f0153f92fbd519
  (x2,y2,z2) = point_doubling(p, x, y, z, a,b3)
  
  print(f"x: {x2:256b}, y: {y2:256b}, z: {z2:256b}")

  # p = 0x7F
  # a = 0x7C
  # b = 0x05

  # g_x = 0x31
  # g_y = 0x0a
  # g_z = 0x0f

  # s = 0xC0

  # (X3, Y3, Z3) = scalar_mult(p, g_x, g_y, g_z, s, a, 3 * b)
