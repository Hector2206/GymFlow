import {
  Component,
  OnInit
} from '@angular/core';

import {
  Router
} from '@angular/router';

import {
  AuthService
} from '../services/auth.service';

@Component({
  selector: 'app-splash',
  standalone: true,
  imports: [],
  templateUrl:
    './splash.html',
  styleUrl:
    './splash.css'
})
export class Splash
implements OnInit {

  constructor(
    private router:
      Router,
    private authService:
      AuthService
  ) {}


  ngOnInit(): void {

    setTimeout(
      () => {

        if (
          this.authService
            .estaAutenticado()
        ) {

          this.router.navigate([
            '/home'
          ]);

          return;
        }

        this.router.navigate([
          '/login'
        ]);
      },
      1800
    );
  }
}
