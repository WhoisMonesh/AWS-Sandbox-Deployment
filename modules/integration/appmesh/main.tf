resource "aws_appmesh_mesh" "this" {
  name = var.mesh_name

  tags = {
    Name = var.mesh_name
    Lab  = "kodekloud"
  }
}
