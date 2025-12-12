import { Routes } from '@angular/router';
import { LandingComponent } from '@pages/landing/landing';
import { LoginComponent } from '@pages/auth/login/login';
import { RegisterComponent } from '@pages/auth/register/register';
import { ForgotPasswordComponent } from '@pages/auth/forgot-password/forgot-password';
import { ResetPasswordComponent } from '@pages/auth/reset-password/reset-password';
import { VerifyEmailComponent } from '@pages/auth/verify-email/verify-email';
import { AdminLayoutComponent } from '@pages/user/admin/admin-layout/admin-layout';
import { DashboardComponent } from '@pages/user/admin/dashboard/dashboard';
import { NotificationsComponent } from '@pages/user/admin/notifications/notifications';
import { UsersComponent } from '@pages/user/admin/users/users';
import { InvitesComponent } from '@pages/user/admin/invites/invites';
import { SpecialtiesComponent } from '@pages/user/admin/specialties/specialties';
import { SchedulesComponent } from '@pages/user/admin/schedules';
import { ScheduleBlocksComponent } from '@pages/user/admin/schedule-blocks';
import { ReportsComponent } from '@pages/user/admin/reports/reports';
import { AuditLogsComponent } from '@pages/user/admin/audit-logs/audit-logs';
import { ProfileComponent } from '@pages/user/admin/profile/profile';

export const routes: Routes = [
  {
    path: '',
    component: LandingComponent
  },
  {
    path: 'auth',
    children: [
      {
        path: 'login',
        component: LoginComponent
      },
      {
        path: 'register',
        component: RegisterComponent
      },
      {
        path: 'forgot-password',
        component: ForgotPasswordComponent
      },
      {
        path: 'reset-password',
        component: ResetPasswordComponent
      },
      {
        path: 'verify-email',
        component: VerifyEmailComponent
      },
      {
        path: '',
        redirectTo: 'login',
        pathMatch: 'full'
      }
    ]
  },
  {
    path: 'user/admin',
    component: AdminLayoutComponent,
    children: [
      {
        path: 'dashboard',
        component: DashboardComponent
      },
      {
        path: 'users',
        component: UsersComponent
      },
      {
        path: 'notifications',
        component: NotificationsComponent
      },
      {
        path: 'invites',
        component: InvitesComponent
      },
      {
        path: 'specialties',
        component: SpecialtiesComponent
      },
      {
        path: 'schedules',
        component: SchedulesComponent
      },
      {
        path: 'schedule-blocks',
        component: ScheduleBlocksComponent
      },
      {
        path: 'reports',
        component: ReportsComponent
      },
      {
        path: 'audit-logs',
        component: AuditLogsComponent
      },
      {
        path: 'profile',
        component: ProfileComponent
      },
      {
        path: '',
        redirectTo: 'dashboard',
        pathMatch: 'full'
      }
    ]
  }
];
