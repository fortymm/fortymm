import { faker } from "@faker-js/faker";

export interface User {
    email: string;
    username: string;
}

export const buildUser = (overrides: Partial<User> = {}): User => {
    const now = Date.now();

    return {
        email: faker.internet.email(),
        username: faker.string.alphanumeric(10),
        ...overrides,
    };
}

export const buildPassword = (): string => faker.internet.password({ length: 20 });