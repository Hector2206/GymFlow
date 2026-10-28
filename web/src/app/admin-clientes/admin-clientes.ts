
import { Component } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-admin-clientes',
  standalone: true,
  imports: [],
  templateUrl: './admin-clientes.html',
  styleUrl: './admin-clientes.css'
})
export class AdminClientes {

  constructor(
    private router: Router
  ) {}

  volverInicio(): void {
    this.router.navigate(['/home']);
  }
}
