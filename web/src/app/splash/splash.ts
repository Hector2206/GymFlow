import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-splash',
  standalone: true,
  imports: [],
  templateUrl: './splash.html',
  styleUrl: './splash.css'
})
export class Splash implements OnInit {

  constructor(private router: Router) {}

  ngOnInit(): void {
    setTimeout(() => {
      this.router.navigate(['/login']);
    }, 5000);
  }
}