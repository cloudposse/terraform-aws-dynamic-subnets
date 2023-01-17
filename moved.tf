# This file is just for "moved" declarations for backward compatibility

moved {
  from = aws_eip.nat_instance
  to   = aws_eip.default
}

moved {
  from = aws_route.default
  to   = aws_route.nat4
}

moved {
  from = aws_route_table_association.public_default
  to   = aws_route_table_association.public
}
