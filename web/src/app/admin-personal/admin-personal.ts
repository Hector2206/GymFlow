
import { Component } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-admin-personal',
  standalone: true,
  imports: [],
  templateUrl: './admin-personal.html',
  styleUrl: './admin-personal.css'
})
export class AdminPersonal {

  constructor(
    private router: Router
  ) {}

  volverInicio(): void {
    this.router.navigate(['/home']);
  }
}
