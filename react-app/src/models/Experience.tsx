export class Experience {
    type: string;
    dateRange: string;
    title: string;
    location: string;
    description: string;
    sortOrder: number

    constructor(
        type: string, 
        dateRange: string,
        title: string,
        location: string,
        description: string,
        sortOrder: number
        ) {
            this.type = type;
            this.dateRange = dateRange;
            this.title = title;
            this.location = location;
            this.description = description;
            this.sortOrder = sortOrder;
        }
}
