export class ApiResponseDto<T> {
  code!: number;
  message!: string;
  data!: T;
}
