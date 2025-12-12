import { Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '@app/shared/components/atoms/icon/icon';
import { AvatarComponent } from '@app/shared/components/atoms/avatar/avatar';
import { BadgeComponent } from '@app/shared/components/atoms/badge/badge';
import { PaginationComponent } from '@app/shared/components/atoms/pagination/pagination';
import { SearchInputComponent } from '@app/shared/components/atoms/search-input/search-input';
import { FilterSelectComponent, FilterOption } from '@app/shared/components/atoms/filter-select/filter-select';
import { TableHeaderComponent } from '@app/shared/components/atoms/table-header/table-header';
import { UserRolePipe } from '@app/core/pipes/user-role.pipe';
import { UserStatusPipe } from '@app/core/pipes/user-status.pipe';
import { UserEditModalComponent } from '@pages/user/admin/users/user-edit-modal/user-edit-modal';
import { UserCreateModalComponent, CreateUserData, CreateUserAction } from '@pages/user/admin/users/user-create-modal/user-create-modal';
import { 
  UsersService, 
  User, 
  UserRole, 
  UserStatus,
  UsersSortOptions 
} from '@app/core/services/users.service';
import { ModalService } from '@app/core/services/modal.service';
import { BadgeVariant } from '@app/shared/components/atoms/badge/badge';

@Component({
  selector: 'app-users',
  imports: [
    FormsModule,
    IconComponent,
    AvatarComponent,
    BadgeComponent,
    PaginationComponent,
    SearchInputComponent,
    FilterSelectComponent,
    TableHeaderComponent,
    UserRolePipe,
    UserStatusPipe,
    UserEditModalComponent,
    UserCreateModalComponent
  ],
  templateUrl: './users.html',
  styleUrl: './users.scss'
})
export class UsersComponent implements OnInit {
  private usersService = inject(UsersService);
  private modalService = inject(ModalService);
  
  users: User[] = [];
  loading = false;
  
  // Modal de edição
  isEditModalOpen = false;
  userToEdit: User | null = null;
  
  // Modal de criação
  isCreateModalOpen = false;
  
  // Filtros
  searchTerm = '';
  roleFilter: UserRole | 'all' = 'all';
  statusFilter: UserStatus | 'all' = 'all';

  roleOptions: FilterOption[] = [
    { value: 'all', label: 'Todos os perfis' },
    { value: 'patient', label: 'Pacientes' },
    { value: 'professional', label: 'Profissionais' },
    { value: 'admin', label: 'Administradores' }
  ];

  statusOptions: FilterOption[] = [
    { value: 'all', label: 'Todos os status' },
    { value: 'active', label: 'Ativos' },
    { value: 'inactive', label: 'Inativos' }
  ];
  
  // Ordenação
  sortField: keyof User = 'id';
  sortDirection: 'asc' | 'desc' = 'asc';
  
  // Paginação
  currentPage = 1;
  pageSize = 10;
  totalUsers = 0;
  totalPages = 0;

  private searchTimeout?: number;

  ngOnInit(): void {
    this.loadUsers();
  }

  loadUsers(): void {
    this.loading = true;
    
    const filter = {
      search: this.searchTerm || undefined,
      role: this.roleFilter,
      status: this.statusFilter
    };

    const sort: UsersSortOptions = {
      field: this.sortField,
      direction: this.sortDirection
    };

    this.usersService.getUsers(filter, sort, this.currentPage, this.pageSize).subscribe({
      next: (response) => {
        this.users = response.data;
        this.totalUsers = response.total;
        this.totalPages = response.totalPages;
        this.loading = false;
      },
      error: (error: Error) => {
        console.error('Erro ao carregar usuários:', error);
        this.loading = false;
      }
    });
  }

  onSearch(value: string): void {
    this.currentPage = 1;
    this.loadUsers();
  }

  onSearchChange(): void {
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }
    
    this.searchTimeout = window.setTimeout(() => {
      this.currentPage = 1;
      this.loadUsers();
    }, 500);
  }

  onFilterChange(): void {
    this.currentPage = 1;
    this.loadUsers();
  }

  sort(field: string): void {
    const typedField = field as keyof User;
    if (this.sortField === typedField) {
      this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
    } else {
      this.sortField = typedField;
      this.sortDirection = 'asc';
    }
    this.loadUsers();
  }

  onPageChange(page: number): void {
    this.currentPage = page;
    this.loadUsers();
  }

  onPageSizeChange(size: number): void {
    this.pageSize = size;
    this.currentPage = 1;
    this.loadUsers();
  }

  getRoleBadgeVariant(role: UserRole): BadgeVariant {
    const variantMap: Record<UserRole, BadgeVariant> = {
      patient: 'info',
      professional: 'primary',
      admin: 'warning'
    };
    return variantMap[role];
  }

  createUser(): void {
    this.isCreateModalOpen = true;
  }

  onCreateModalClose(): void {
    this.isCreateModalOpen = false;
  }

  onCreateModalSubmit(event: { data: CreateUserData; action: CreateUserAction }): void {
    const { data, action } = event;

    switch (action) {
      case 'create':
        this.handleCreateUser(data);
        break;
      case 'generate-link':
        this.handleGenerateLink(data);
        break;
      case 'send-email':
        this.handleSendEmail(data);
        break;
    }
  }

  private handleCreateUser(data: CreateUserData): void {
    // TODO: Implementar criação de usuário no backend
    console.log('Criar usuário:', data);
    this.isCreateModalOpen = false;
    this.modalService.alert({
      title: 'Sucesso',
      message: 'Usuário criado com sucesso.',
      confirmText: 'OK',
      variant: 'success'
    }).subscribe(() => {
      this.loadUsers();
    });
  }

  private handleGenerateLink(data: CreateUserData): void {
    // TODO: Implementar geração de link no backend
    const mockLink = `https://telecuidar.com/register?token=abc123&role=${data.role}`;
    console.log('Link gerado:', mockLink);
    this.isCreateModalOpen = false;
    
    // Copiar link para área de transferência
    navigator.clipboard.writeText(mockLink).then(() => {
      this.modalService.alert({
        title: 'Link Gerado',
        message: `Link de cadastro copiado para a área de transferência:\n\n${mockLink}`,
        confirmText: 'OK',
        variant: 'success'
      }).subscribe();
    });
  }

  private handleSendEmail(data: CreateUserData): void {
    // TODO: Implementar envio de email no backend
    console.log('Enviar email para:', data.email);
    this.isCreateModalOpen = false;
    this.modalService.alert({
      title: 'Email Enviado',
      message: `Link de cadastro enviado para ${data.email}`,
      confirmText: 'OK',
      variant: 'success'
    }).subscribe();
  }

  editUser(id: string): void {
    const user = this.users.find(u => u.id === id);
    if (user) {
      this.userToEdit = user;
      this.isEditModalOpen = true;
    }
  }

  onEditModalClose(): void {
    this.isEditModalOpen = false;
    this.userToEdit = null;
  }

  onEditModalSave(updatedUser: User): void {
    this.usersService.updateUser(updatedUser.id, updatedUser).subscribe({
      next: () => {
        this.loadUsers();
        this.isEditModalOpen = false;
        this.userToEdit = null;
        this.modalService.alert({
          title: 'Sucesso',
          message: 'Usuário atualizado com sucesso.',
          confirmText: 'OK',
          variant: 'success'
        }).subscribe();
      },
      error: (error: Error) => {
        console.error('Erro ao atualizar usuário:', error);
        this.modalService.alert({
          title: 'Erro',
          message: 'Ocorreu um erro ao atualizar o usuário. Tente novamente.',
          confirmText: 'OK',
          variant: 'danger'
        }).subscribe();
      }
    });
  }

  deleteUser(id: string): void {
    this.modalService.confirm({
      title: 'Confirmar Exclusão',
      message: 'Tem certeza que deseja excluir este usuário? Esta ação não pode ser desfeita.',
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
      variant: 'danger'
    }).subscribe({
      next: (result) => {
        if (result.confirmed) {
          this.usersService.deleteUser(id).subscribe({
            next: () => {
              this.loadUsers();
              this.modalService.alert({
                title: 'Sucesso',
                message: 'Usuário excluído com sucesso.',
                confirmText: 'OK',
                variant: 'success'
              }).subscribe();
            },
            error: (error: Error) => {
              console.error('Erro ao excluir usuário:', error);
              this.modalService.alert({
                title: 'Erro',
                message: 'Ocorreu um erro ao excluir o usuário. Tente novamente.',
                confirmText: 'OK',
                variant: 'danger'
              }).subscribe();
            }
          });
        }
      }
    });
  }
}
